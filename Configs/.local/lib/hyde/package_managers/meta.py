"""Package manager metadata types."""

from dataclasses import dataclass


@dataclass(slots=True)
class PMMetadata:
    """Metadata that a package manager module declares about itself."""
    # Display name (defaults to module name)
    name: str = ""
    # Priority: lower = higher priority (checked first)
    # Base package managers: 10, AUR helpers: 20, Others: 30
    priority: int = 20
    # List of managers this one conflicts with/replaces
    # If both are available, the higher priority (lower number) wins
    conflicts: tuple[str, ...] = ()
    # Whether this is a base system package manager
    is_base: bool = False
    # Manager this one overrides (takes precedence when both available)
    overrides: tuple[str, ...] = ()


# Default metadata for managers that don't declare one
DEFAULT_META = PMMetadata()
