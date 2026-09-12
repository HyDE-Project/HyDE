local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = root .. "../../Configs/.local/lib/hyde/?.lua;" .. package.path
local gpuinfo = require("gpuinfo")

local failures = 0
local function check(condition, message)
    if not condition then
        failures = failures + 1
        print("    fail: " .. message)
    end
end

local function write_file(path, content)
    local f = assert(io.open(path, "w"))
    f:write(content)
    f:close()
end

local work_dir = os.getenv("GPUINFO_TEST_WORK_DIR")
assert(work_dir, "GPUINFO_TEST_WORK_DIR must be set by the test wrapper")

-- A fake PCI bus with one Intel display controller (class 0x030000) and one
-- unrelated device (class 0x060000, a host bridge -- must be ignored).
local pci_dir = work_dir .. "/pci"
os.execute("mkdir -p " .. pci_dir .. "/0000:00:02.0 " .. pci_dir .. "/0000:00:00.0")
write_file(pci_dir .. "/0000:00:02.0/class", "0x030000\n")
write_file(pci_dir .. "/0000:00:02.0/vendor", "0x8086\n")
write_file(pci_dir .. "/0000:00:00.0/class", "0x060000\n")
write_file(pci_dir .. "/0000:00:00.0/vendor", "0x8086\n")

-- A fake lspci that only responds to the exact address gpuinfo asks for, so
-- the test also proves detect_vendor asks for that one address and not a
-- broad bus scan.
local fake_bin = work_dir .. "/bin"
os.execute("mkdir -p " .. fake_bin)
write_file(fake_bin .. "/lspci", [[#!/bin/sh
if [ "$3" = "0000:00:02.0" ]; then
    echo "00:02.0 VGA compatible controller [0300]: Intel Corporation Iris Xe Graphics [8086:9a49] (rev 01)"
else
    echo "unexpected address: $3" >&2
    exit 1
fi
]])
os.execute("chmod +x " .. fake_bin .. "/lspci")

local result = gpuinfo.detect_vendor({
    pci_dir = pci_dir,
    modules_file = work_dir .. "/nonexistent-modules",
    path_dirs = {fake_bin},
    lspci_cmd = "lspci",
})

check(result.intel == true, "an Intel display controller (class 0x030000, vendor 0x8086) was not detected")
check(result.nvidia == false, "nvidia was incorrectly detected with no matching PCI device")
check(result.amd == false, "amd was incorrectly detected with no matching PCI device")
check(result.intel_addr == "0000:00:02.0", "intel_addr was not the display controller's own address: got " .. tostring(result.intel_addr))
check(
    result.intel_gpu == "Iris Xe Graphics",
    "intel_gpu was not resolved from the single targeted lspci call: got " .. tostring(result.intel_gpu)
)

-- Some chips (caught live on real Kaby Lake-U hardware) carry a marketing-
-- name bracket ahead of the [ids] one -- it must survive stripping, since
-- it's the name most people actually know the card by.
local marketing_dir = work_dir .. "/pci_marketing"
os.execute("mkdir -p " .. marketing_dir .. "/0000:00:02.0")
write_file(marketing_dir .. "/0000:00:02.0/class", "0x030000\n")
write_file(marketing_dir .. "/0000:00:02.0/vendor", "0x8086\n")
write_file(fake_bin .. "/lspci", [[#!/bin/sh
if [ "$3" = "0000:00:02.0" ]; then
    echo "00:02.0 VGA compatible controller [0300]: Intel Corporation Kaby Lake-U GT2 [HD Graphics 620] [8086:5916] (rev 02)"
else
    echo "unexpected address: $3" >&2
    exit 1
fi
]])
os.execute("chmod +x " .. fake_bin .. "/lspci")

local marketing_result = gpuinfo.detect_vendor({
    pci_dir = marketing_dir,
    modules_file = work_dir .. "/nonexistent-modules",
    path_dirs = {fake_bin},
    lspci_cmd = "lspci",
})
check(
    marketing_result.intel_gpu == "Kaby Lake-U GT2 [HD Graphics 620]",
    "a marketing-name bracket ahead of the [ids] one did not survive: got " .. tostring(marketing_result.intel_gpu)
)

-- AMD's pci.ids vendor string carries its own "[AMD/ATI]" alias bracket
-- ahead of the codename -- that one must NOT survive (it's not a
-- marketing name, it sits before the codename, and it would otherwise
-- duplicate the "AMD " prefix gpuinfo.lua's own field assembly adds).
local amd_marketing_dir = work_dir .. "/pci_amd_marketing"
os.execute("mkdir -p " .. amd_marketing_dir .. "/0000:03:00.0")
write_file(amd_marketing_dir .. "/0000:03:00.0/class", "0x030000\n")
write_file(amd_marketing_dir .. "/0000:03:00.0/vendor", "0x1002\n")
write_file(fake_bin .. "/lspci", [[#!/bin/sh
if [ "$3" = "0000:03:00.0" ]; then
    echo "03:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 23 [Radeon RX 6600/6600 XT/6600M] [1002:73ff] (rev c1)"
else
    echo "unexpected address: $3" >&2
    exit 1
fi
]])
os.execute("chmod +x " .. fake_bin .. "/lspci")

local amd_marketing_result = gpuinfo.detect_vendor({
    pci_dir = amd_marketing_dir,
    modules_file = work_dir .. "/nonexistent-modules",
    path_dirs = {fake_bin},
    lspci_cmd = "lspci",
})
check(
    amd_marketing_result.amd_gpu == "Navi 23 [Radeon RX 6600/6600 XT/6600M]",
    "AMD's own '[AMD/ATI]' vendor-alias bracket leaked into the name: got " .. tostring(amd_marketing_result.amd_gpu)
)

-- Out-of-spec: a device whose class file holds garbage (a race with a device
-- being hot-unplugged, or a kernel quirk) must be skipped, not crash the scan.
local garbage_dir = work_dir .. "/pci_garbage"
os.execute("mkdir -p " .. garbage_dir .. "/0000:01:00.0")
write_file(garbage_dir .. "/0000:01:00.0/class", "not-a-hex-value\n")
write_file(garbage_dir .. "/0000:01:00.0/vendor", "0x10de\n")
local garbage_result = gpuinfo.detect_vendor({
    pci_dir = garbage_dir,
    modules_file = work_dir .. "/nonexistent-modules",
    path_dirs = {fake_bin},
})
check(garbage_result.nvidia == false, "a device with a garbage class file was still detected as a GPU")

-- NVIDIA hardware remains selectable even without nvidia-smi: LACT is the
-- runtime query backend and may provide the driver data independently.
local nodriver_dir = work_dir .. "/pci_nodriver"
os.execute("mkdir -p " .. nodriver_dir .. "/0000:02:00.0")
write_file(nodriver_dir .. "/0000:02:00.0/class", "0x030200\n")  -- 3D controller
write_file(nodriver_dir .. "/0000:02:00.0/vendor", "0x10de\n")   -- nvidia
write_file(fake_bin .. "/lspci", [[#!/bin/sh
if [ "$3" = "0000:02:00.0" ]; then
    echo "02:00.0 3D controller [0302]: NVIDIA Corporation GA106M [2504:1234]"
else
    echo "unexpected address: $3" >&2
    exit 1
fi
]])
os.execute("chmod +x " .. fake_bin .. "/lspci")

-- Empty modules file (no nouveau) and empty bin dir (no nvidia-smi)
local empty_bin = work_dir .. "/empty_bin"
os.execute("mkdir -p " .. empty_bin)
local nodriver_modules = work_dir .. "/modules_no_nouveau"
write_file(nodriver_modules, "some_other_module 1000 1 -\n")

local nodriver_result = gpuinfo.detect_vendor({
    pci_dir = nodriver_dir,
    modules_file = nodriver_modules,
    path_dirs = {empty_bin},
    lspci_cmd = "lspci",
})
check(
    nodriver_result.nvidia == true,
    "PCI-detected NVIDIA hardware was not retained for LACT, got: " .. tostring(nodriver_result.nvidia)
)
check(
    nodriver_result.nvidia_addr == "0000:02:00.0",
    "nvidia_addr should record the PCI address for LACT"
)

-- Same PCI device, but with nouveau actually loaded this time -- and with
-- lspci resolving a real name (as it will on an actual nouveau host), not
-- the "Linux" placeholder. nvidia_nouveau must still record nouveau's
-- presence independently of whatever name got resolved (caught in review:
-- cli_main used to infer "is this nouveau" by comparing nvidia_gpu against
-- the literal placeholder string "Linux", which is only ever set when PCI
-- detection found *no* resolvable name -- a real name here would have
-- silently misidentified this exact case as "not nouveau" and sent it down
-- the nvidia-smi path instead, which nouveau has no way to answer).
local nouveau_modules = work_dir .. "/modules_with_nouveau"
write_file(nouveau_modules, "nouveau 2097152 4 -\nsome_other_module 1000 1 -\n")
local nouveau_result = gpuinfo.detect_vendor({
    pci_dir = nodriver_dir,
    modules_file = nouveau_modules,
    path_dirs = {fake_bin},
    lspci_cmd = "lspci",
})
check(
    nouveau_result.nvidia_gpu == "GA106M",
    "a real lspci-resolved name should survive nouveau detection: got " .. tostring(nouveau_result.nvidia_gpu)
)
check(
    nouveau_result.nvidia_nouveau == true,
    "nouveau presence was not recorded independently of the resolved GPU name"
)
check(nouveau_result.nvidia == true, "nvidia should be true once nouveau provides a way to query it")

os.exit(failures == 0 and 0 or 1)
