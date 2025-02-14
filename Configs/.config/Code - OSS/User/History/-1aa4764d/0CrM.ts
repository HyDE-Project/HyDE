import 'lib/init'

import { App } from 'astal/gtk3'
import { Bar, Run, Settings } from 'windows'

function main() {
  App.get_monitors().map(Bar)
  Run()
  Settings()
  //Indicator()
}

function requestHandler(request: string, res: (response: any) => void) {
  const args = request.split(' ')
  if (args[0] === 'popup') {
    res('Toggle popup widget')
  }
  res('unknown command')
}

App.start({
  main,
  requestHandler,
  instanceName: 'desktop',
})
