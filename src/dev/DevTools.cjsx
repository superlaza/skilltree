React = require 'react'
{createDevTools} = require 'redux-devtools'

{default: LogMonitor} = require 'redux-devtools-log-monitor'
{default: DockMonitor} = require 'redux-devtools-dock-monitor'

DevTools = createDevTools(
		<DockMonitor toggleVisibilityKey='ctrl-h' changePositionKey='ctrl-q'>
			<LogMonitor theme='tomorrow'/>
		</DockMonitor>
)
module.exports = DevTools