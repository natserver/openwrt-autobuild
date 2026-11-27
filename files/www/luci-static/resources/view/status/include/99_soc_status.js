'use strict';
'require baseclass';
'require rpc';

// Independent status panel added by the JDC AX1800 Pro firmware.
// It does not depend on the upstream 10_system.js rendering path.
var callSocStats = rpc.declare({
	object: 'luci',
	method: 'getHomepageStats'
});

return baseclass.extend({
	title: _('SoC status'),

	load: function() {
		return L.resolveDefault(callSocStats(), {});
	},

	render: function(data) {
		if (!L.isObject(data) || data.ok !== true)
			return null;

		var fields = [
			_('CPU frequency'),        data.cpufreq || '-',
			_('CPU governor'),         data.governor || '-',
			_('CPU temperature'),      data.cputemp || '-',
			_('WiFi temperature'),     data.wifitemp || '-',
			_('CPU usage'),            data.cpuusage || '-',
			_('NSS usage'),            data.nssusage || '-'
		];

		var table = E('table', { 'class': 'table' });

		for (var i = 0; i < fields.length; i += 2) {
			table.appendChild(E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [ fields[i] ]),
				E('td', { 'class': 'td left' }, [ fields[i + 1] ])
			]));
		}

		return table;
	}
});
