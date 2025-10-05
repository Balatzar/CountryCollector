extends Node

# Size categories for countries
enum Size {
	MICROSCOPIC,
	SMALL,
	MEDIUM,
	BIG,
	HUGE
}

# Dictionary mapping ISO 3166-1 alpha-2 country codes to country data
# Each entry contains: { "human_name": String, "size": Size }
const COUNTRY_NAMES = {
	# A
	"AE": {"human_name": "United Arab Emirates", "size": Size.MEDIUM},
	"AF": {"human_name": "Afghanistan", "size": Size.BIG},
	"AL": {"human_name": "Albania", "size": Size.SMALL},
	"AM": {"human_name": "Armenia", "size": Size.SMALL},
	"AO": {"human_name": "Angola", "size": Size.BIG},
	"AR": {"human_name": "Argentina", "size": Size.HUGE},
	"AT": {"human_name": "Austria", "size": Size.MEDIUM},
	"AU": {"human_name": "Australia", "size": Size.HUGE},
	"AZ": {"human_name": "Azerbaijan", "size": Size.MEDIUM},

	# B
	"BA": {"human_name": "Bosnia and Herzegovina", "size": Size.SMALL},
	"BD": {"human_name": "Bangladesh", "size": Size.MEDIUM},
	"BE": {"human_name": "Belgium", "size": Size.SMALL},
	"BF": {"human_name": "Burkina Faso", "size": Size.MEDIUM},
	"BG": {"human_name": "Bulgaria", "size": Size.MEDIUM},
	"BI": {"human_name": "Burundi", "size": Size.SMALL},
	"BJ": {"human_name": "Benin", "size": Size.SMALL},
	"BN": {"human_name": "Brunei", "size": Size.MICROSCOPIC},
	"BO": {"human_name": "Bolivia", "size": Size.BIG},
	"BR": {"human_name": "Brazil", "size": Size.HUGE},
	"BS": {"human_name": "Bahamas", "size": Size.MICROSCOPIC},
	"BT": {"human_name": "Bhutan", "size": Size.SMALL},
	"BW": {"human_name": "Botswana", "size": Size.MEDIUM},
	"BY": {"human_name": "Belarus", "size": Size.MEDIUM},
	"BZ": {"human_name": "Belize", "size": Size.SMALL},

	# C
	"CA": {"human_name": "Canada", "size": Size.HUGE},
	"CD": {"human_name": "Democratic Republic of the Congo", "size": Size.HUGE},
	"CF": {"human_name": "Central African Republic", "size": Size.BIG},
	"CG": {"human_name": "Republic of the Congo", "size": Size.MEDIUM},
	"CH": {"human_name": "Switzerland", "size": Size.SMALL},
	"CI": {"human_name": "Côte d'Ivoire", "size": Size.MEDIUM},
	"CL": {"human_name": "Chile", "size": Size.BIG},
	"CM": {"human_name": "Cameroon", "size": Size.MEDIUM},
	"CN": {"human_name": "China", "size": Size.HUGE},
	"CO": {"human_name": "Colombia", "size": Size.BIG},
	"CR": {"human_name": "Costa Rica", "size": Size.SMALL},
	"CU": {"human_name": "Cuba", "size": Size.SMALL},
	"CV": {"human_name": "Cape Verde", "size": Size.MICROSCOPIC},
	"CY": {"human_name": "Cyprus", "size": Size.MICROSCOPIC},
	"CZ": {"human_name": "Czech Republic", "size": Size.MEDIUM},

	# D
	"DE": {"human_name": "Germany", "size": Size.MEDIUM},
	"DJ": {"human_name": "Djibouti", "size": Size.SMALL},
	"DK": {"human_name": "Denmark", "size": Size.SMALL},
	"DM": {"human_name": "Dominica", "size": Size.MICROSCOPIC},
	"DO": {"human_name": "Dominican Republic", "size": Size.SMALL},
	"DZ": {"human_name": "Algeria", "size": Size.HUGE},

	# E
	"EC": {"human_name": "Ecuador", "size": Size.MEDIUM},
	"EE": {"human_name": "Estonia", "size": Size.SMALL},
	"EG": {"human_name": "Egypt", "size": Size.BIG},
	"ER": {"human_name": "Eritrea", "size": Size.SMALL},
	"ES": {"human_name": "Spain", "size": Size.MEDIUM},
	"ET": {"human_name": "Ethiopia", "size": Size.BIG},

	# F
	"FI": {"human_name": "Finland", "size": Size.MEDIUM},
	"FK": {"human_name": "Falkland Islands", "size": Size.MICROSCOPIC},
	"FR": {"human_name": "France", "size": Size.MEDIUM},

	# G
	"GA": {"human_name": "Gabon", "size": Size.MEDIUM},
	"GB": {"human_name": "United Kingdom", "size": Size.MEDIUM},
	"GE": {"human_name": "Georgia", "size": Size.SMALL},
	"GH": {"human_name": "Ghana", "size": Size.MEDIUM},
	"GL": {"human_name": "Greenland", "size": Size.HUGE},
	"GM": {"human_name": "Gambia", "size": Size.SMALL},
	"GN": {"human_name": "Guinea", "size": Size.MEDIUM},
	"GQ": {"human_name": "Equatorial Guinea", "size": Size.SMALL},
	"GR": {"human_name": "Greece", "size": Size.MEDIUM},
	"GT": {"human_name": "Guatemala", "size": Size.SMALL},
	"GW": {"human_name": "Guinea-Bissau", "size": Size.SMALL},
	"GY": {"human_name": "Guyana", "size": Size.MEDIUM},

	# H
	"HN": {"human_name": "Honduras", "size": Size.SMALL},
	"HR": {"human_name": "Croatia", "size": Size.SMALL},
	"HT": {"human_name": "Haiti", "size": Size.SMALL},
	"HU": {"human_name": "Hungary", "size": Size.MEDIUM},

	# I
	"ID": {"human_name": "Indonesia", "size": Size.BIG},
	"IE": {"human_name": "Ireland", "size": Size.SMALL},
	"IL": {"human_name": "Israel", "size": Size.SMALL},
	"IN": {"human_name": "India", "size": Size.HUGE},
	"IQ": {"human_name": "Iraq", "size": Size.MEDIUM},
	"IR": {"human_name": "Iran", "size": Size.BIG},
	"IS": {"human_name": "Iceland", "size": Size.SMALL},
	"IT": {"human_name": "Italy", "size": Size.MEDIUM},

	# J
	"JM": {"human_name": "Jamaica", "size": Size.MICROSCOPIC},
	"JO": {"human_name": "Jordan", "size": Size.MEDIUM},
	"JP": {"human_name": "Japan", "size": Size.MEDIUM},

	# K
	"KE": {"human_name": "Kenya", "size": Size.MEDIUM},
	"KG": {"human_name": "Kyrgyzstan", "size": Size.MEDIUM},
	"KH": {"human_name": "Cambodia", "size": Size.MEDIUM},
	"KM": {"human_name": "Comoros", "size": Size.MICROSCOPIC},
	"KP": {"human_name": "North Korea", "size": Size.SMALL},
	"KR": {"human_name": "South Korea", "size": Size.SMALL},
	"KW": {"human_name": "Kuwait", "size": Size.SMALL},
	"KZ": {"human_name": "Kazakhstan", "size": Size.HUGE},

	# L
	"LA": {"human_name": "Laos", "size": Size.MEDIUM},
	"LB": {"human_name": "Lebanon", "size": Size.SMALL},
	"LC": {"human_name": "Saint Lucia", "size": Size.MICROSCOPIC},
	"LK": {"human_name": "Sri Lanka", "size": Size.SMALL},
	"LR": {"human_name": "Liberia", "size": Size.SMALL},
	"LS": {"human_name": "Lesotho", "size": Size.SMALL},
	"LT": {"human_name": "Lithuania", "size": Size.SMALL},
	"LU": {"human_name": "Luxembourg", "size": Size.MICROSCOPIC},
	"LV": {"human_name": "Latvia", "size": Size.SMALL},
	"LY": {"human_name": "Libya", "size": Size.HUGE},

	# M
	"MA": {"human_name": "Morocco", "size": Size.MEDIUM},
	"MD": {"human_name": "Moldova", "size": Size.SMALL},
	"ME": {"human_name": "Montenegro", "size": Size.MICROSCOPIC},
	"MG": {"human_name": "Madagascar", "size": Size.MEDIUM},
	"MK": {"human_name": "North Macedonia", "size": Size.SMALL},
	"ML": {"human_name": "Mali", "size": Size.BIG},
	"MM": {"human_name": "Myanmar", "size": Size.BIG},
	"MN": {"human_name": "Mongolia", "size": Size.BIG},
	"MR": {"human_name": "Mauritania", "size": Size.BIG},
	"MT": {"human_name": "Malta", "size": Size.MICROSCOPIC},
	"MU": {"human_name": "Mauritius", "size": Size.MICROSCOPIC},
	"MV": {"human_name": "Maldives", "size": Size.MICROSCOPIC},
	"MW": {"human_name": "Malawi", "size": Size.SMALL},
	"MX": {"human_name": "Mexico", "size": Size.BIG},
	"MY": {"human_name": "Malaysia", "size": Size.MEDIUM},
	"MZ": {"human_name": "Mozambique", "size": Size.BIG},

	# N
	"NA": {"human_name": "Namibia", "size": Size.BIG},
	"NC": {"human_name": "New Caledonia", "size": Size.SMALL},
	"NE": {"human_name": "Niger", "size": Size.BIG},
	"NG": {"human_name": "Nigeria", "size": Size.MEDIUM},
	"NI": {"human_name": "Nicaragua", "size": Size.SMALL},
	"NL": {"human_name": "Netherlands", "size": Size.SMALL},
	"NO": {"human_name": "Norway", "size": Size.MEDIUM},
	"NP": {"human_name": "Nepal", "size": Size.MEDIUM},
	"NZ": {"human_name": "New Zealand", "size": Size.MEDIUM},

	# O
	"OM": {"human_name": "Oman", "size": Size.MEDIUM},

	# P
	"PA": {"human_name": "Panama", "size": Size.SMALL},
	"PE": {"human_name": "Peru", "size": Size.BIG},
	"PG": {"human_name": "Papua New Guinea", "size": Size.MEDIUM},
	"PH": {"human_name": "Philippines", "size": Size.MEDIUM},
	"PK": {"human_name": "Pakistan", "size": Size.BIG},
	"PL": {"human_name": "Poland", "size": Size.MEDIUM},
	"PR": {"human_name": "Puerto Rico", "size": Size.MICROSCOPIC},
	"PT": {"human_name": "Portugal", "size": Size.SMALL},
	"PY": {"human_name": "Paraguay", "size": Size.MEDIUM},

	# Q
	"QA": {"human_name": "Qatar", "size": Size.MICROSCOPIC},

	# R
	"RO": {"human_name": "Romania", "size": Size.MEDIUM},
	"RS": {"human_name": "Serbia", "size": Size.SMALL},
	"RU": {"human_name": "Russia", "size": Size.HUGE},
	"RW": {"human_name": "Rwanda", "size": Size.SMALL},

	# S
	"SA": {"human_name": "Saudi Arabia", "size": Size.HUGE},
	"SB": {"human_name": "Solomon Islands", "size": Size.SMALL},
	"SC": {"human_name": "Seychelles", "size": Size.MICROSCOPIC},
	"SD": {"human_name": "Sudan", "size": Size.HUGE},
	"SE": {"human_name": "Sweden", "size": Size.MEDIUM},
	"SG": {"human_name": "Singapore", "size": Size.MICROSCOPIC},
	"SI": {"human_name": "Slovenia", "size": Size.SMALL},
	"SK": {"human_name": "Slovakia", "size": Size.SMALL},
	"SL": {"human_name": "Sierra Leone", "size": Size.SMALL},
	"SN": {"human_name": "Senegal", "size": Size.MEDIUM},
	"SO": {"human_name": "Somalia", "size": Size.BIG},
	"SR": {"human_name": "Suriname", "size": Size.MEDIUM},
	"SS": {"human_name": "South Sudan", "size": Size.BIG},
	"ST": {"human_name": "São Tomé and Príncipe", "size": Size.MICROSCOPIC},
	"SV": {"human_name": "El Salvador", "size": Size.SMALL},
	"SY": {"human_name": "Syria", "size": Size.MEDIUM},
	"SZ": {"human_name": "Eswatini", "size": Size.SMALL},

	# T
	"TD": {"human_name": "Chad", "size": Size.BIG},
	"TG": {"human_name": "Togo", "size": Size.SMALL},
	"TH": {"human_name": "Thailand", "size": Size.MEDIUM},
	"TJ": {"human_name": "Tajikistan", "size": Size.MEDIUM},
	"TM": {"human_name": "Turkmenistan", "size": Size.MEDIUM},
	"TN": {"human_name": "Tunisia", "size": Size.MEDIUM},
	"TR": {"human_name": "Turkey", "size": Size.BIG},
	"TT": {"human_name": "Trinidad and Tobago", "size": Size.MICROSCOPIC},
	"TW": {"human_name": "Taiwan", "size": Size.SMALL},
	"TZ": {"human_name": "Tanzania", "size": Size.BIG},

	# U
	"UA": {"human_name": "Ukraine", "size": Size.BIG},
	"UG": {"human_name": "Uganda", "size": Size.MEDIUM},
	"US": {"human_name": "United States", "size": Size.HUGE},
	"UY": {"human_name": "Uruguay", "size": Size.MEDIUM},
	"UZ": {"human_name": "Uzbekistan", "size": Size.MEDIUM},

	# V
	"VC": {"human_name": "Saint Vincent and the Grenadines", "size": Size.MICROSCOPIC},
	"VE": {"human_name": "Venezuela", "size": Size.BIG},
	"VN": {"human_name": "Vietnam", "size": Size.MEDIUM},
	"VU": {"human_name": "Vanuatu", "size": Size.SMALL},

	# Y
	"YE": {"human_name": "Yemen", "size": Size.MEDIUM},

	# Z
	"ZA": {"human_name": "South Africa", "size": Size.BIG},
	"ZM": {"human_name": "Zambia", "size": Size.BIG},
	"ZW": {"human_name": "Zimbabwe", "size": Size.MEDIUM},
}

# Get the full country data for a country code
static func get_country_data(country_code: String) -> Dictionary:
	return COUNTRY_NAMES.get(country_code, {"human_name": country_code, "size": Size.MEDIUM})

# Get the full name for a country code, returns the code itself if not found
static func get_country_name(country_code: String) -> String:
	var data = get_country_data(country_code)
	return data["human_name"]

# Get the size category for a country code
static func get_country_size(country_code: String) -> Size:
	var data = get_country_data(country_code)
	return data["size"]
