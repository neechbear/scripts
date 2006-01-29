%THEME = (
	'switch' => {
		fontcolor => 'white',	fixedsize => 'true',	fontname => 'Arial',	fontsize => 8,
		style     => 'filled',	shape     => 'circle',	color    => 'navy',	height   => 0.75,
	},
	'rtr-border' => {
		fontcolor => 'black',	fixedsize => 'true',	fontname => 'Arial',	fontsize => 8,
		style     => 'filled',	shape     => 'Mcircle',	color    => 'orangered1',	height   => 0.75,
	},
	'rtr-access' => {
		fontcolor => 'black',	fixedsize => 'true',	fontname => 'Arial',	fontsize => 8,
		style     => 'filled',	shape     => 'Mcircle',	color    => 'darksalmon',	height   => 0.75,
	},
	'rtr' => {
		fontcolor => 'black',	fixedsize => 'true',	fontname => 'Arial',	fontsize => 8,
		style     => 'filled',	shape     => 'Mcircle',	color    => 'skyblue',	height   => 0.75,
	},
	'*' => {
		fontcolor => 'black',	fixedsize => 'false',	fontname => 'Arial',	fontsize => 8,
		style     => 'filled',	shape     => 'box',	color    => 'palegoldenrod',
	},
	'transit' => {
		fontcolor => 'black',	fixedsize => 'true',	fontname => 'Arial',	fontsize => 8,
		style     => 'filled',	shape     => 'doublecircle',	color    => 'orangered1',	height   => 0.75,
	},
	'the_internet' => {
		fontcolor => 'black',	fixedsize => 'true',	fontname => 'Arial',	fontsize => 8,	width	=> 1.50,
		style     => 'filled',	shape     => 'tripleoctagon',	color    => 'forestgreen',	height   => 1.50,
	},
);

$THEME{'270.ge11-0.mpr2.pao1.us.mfnx.net'}	= {%{$THEME{'transit'}}};
$THEME{'64.124.128.core1.pao.mfnx.net'}		= {%{$THEME{'transit'}}};
$THEME{'lvl3gw.thn.packetexchange.net'}		= {%{$THEME{'transit'}}};
$THEME{'Serial5-0-1.GW3.LND10.ALTER.NET'}	= {%{$THEME{'transit'}}};
$THEME{'linx-1.ftech.net'}			= {%{$THEME{'transit'}}};
$THEME{'linx-2.ftech.net'}			= {%{$THEME{'transit'}}};

$THEME{'270.ge11-0.mpr2.pao1.us.mfnx.net'}->{label}	= '270.ge11-0\n.mpr2.pao1.us\n.mfnx.net';
$THEME{'64.124.128.core1.pao.mfnx.net'}->{label}	= '64.124.128\n.core1.pao\n.mfnx.net';
$THEME{'lvl3gw.thn.packetexchange.net'}->{label}	= 'lvl3gw.thn\n.packetexchange.net';
$THEME{'Serial5-0-1.GW3.LND10.ALTER.NET'}->{label}	= 'Serial5-0-1.GW3\n.LND10.ALTER.NET';

$THEME{'arod.paix.ca.us.ftech.net'}		= {%{$THEME{'rtr-border'}}};
$THEME{'balin.paix.ca.us.ftech.net'}		= {%{$THEME{'rtr-border'}}};

$THEME{'core-a.ensign.ftech.net'}		= {%{$THEME{'rtr'}}};

$THEME{'rtr-dial'} 		= {%{$THEME{'rtr-access'}}};
$THEME{'rtr-dial'}->{color}	= 'lightpink';

