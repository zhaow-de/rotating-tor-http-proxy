![GitHub](https://img.shields.io/github/license/zhaow-de/rotating-tor-http-proxy)
![Docker Image Version (latest semver)](https://img.shields.io/docker/v/zhaowde/rotating-tor-http-proxy?sort=semver)
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/zhaow-de/rotating-tor-http-proxy/auto-upgrade.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/zhaowde/rotating-tor-http-proxy.svg)](https://hub.docker.com/r/zhaowde/rotating-tor-http-proxy/)
![Docker Image Size (latest semver)](https://img.shields.io/docker/image-size/zhaowde/rotating-tor-http-proxy?sort=semver)

# rotating-tor-http-proxy

This Docker image provides one HTTP proxy endpoint with many IP addresses for use scenarios like web crawling.

![Screenshot](https://raw.githubusercontent.com/zhaow-de/rotating-tor-http-proxy/main/images/screenshot_1.gif)

Behind the scene, it has a HAProxy sitting in front of multiple pairs of Privoxy-Tor. The HAProxy dispatches the incoming
requests to the Privoxy instances with a round-robin strategy. 

## Usage

This image is multi-platform enabled, currently supporting:
- amd64 (x86_64)
- arm64 (aarch64)
- arm/v7 (armhf)
- arm/v6 (armel)

### Simple case
```shell
docker run --rm -it -p 3128:3128 zhaowde/rotating-tor-http-proxy
```
At the host, `127.0.0.1:3128` is the HTTP/HTTPS proxy address.

### Moreover

```shell
docker run --rm -it -p 3128:3128 -p 4444:4444 -e "TOR_INSTANCES=5" -e "TOR_REBUILD_INTERVAL=3600" -e "TOR_EXIT_COUNTRY=de,ch,at" zhaowde/rotating-tor-http-proxy
```

#### Port `4444/TCP`

Port `4444/TCP` can be mapped to the host if HAProxy stats information is needed. With `docker run -p 4444:4444`, the HAProxy statistics
report is available at http://127.0.0.1:4444.  An [article](https://www.haproxy.com/blog/exploring-the-haproxy-stats-page/) from the
HAProxy official blog explains in detail how to understand this report.

#### `TOR_INSTANCES`

Environment variable `TOR_INSTANCES` can be used to config the number of concurrent Tor clients (as well as the associated Privoxy 
instances). The default is 10, and the valid value is purposely limited to the range between 1 and 40. 

#### `TOR_REBUILD_INTERVAL`
Each Tor client attempts to build a new circuit (results in a new outbound IP address) every 30 seconds. Every 30 minutes, this image
rebuilds all the circuits. This interval can be changed with environment variable `TOR_REBUILD_INTERVAL`, the default value is 1800
seconds, while it can be set up any number greater than 600 seconds.

#### `TOR_EXIT_COUNTRY`

For some crawling tasks, it requires limiting the IP addresses to a certain country to avoid triggering the unnecessary recaptcha verification. 
Environment variable `TOR_EXIT_COUNTRY` can be used to specify a country (or a list of countries).
Please note the following remarks:
 * **Note 1**: Modifying the way that Tor creates its circuits is strongly discouraged, overriding the entry/exit nodes can compromise the anonymity.
 * **Note 2**: The tor bridge is configured to strictly respect the exit countries if it is specified.
   For the countries with too fewer exit nodes (e.g., Switzerland), it would take significantly longer time to build up the circuit.
 * **Note 3**: The environment variable accepts a single country code (e.g., `TOR_EXIT_COUNTRY=de`) or a comma-separated list (e.g., `TOR_EXIT_COUNTRY=de,at,ch`)
 * **Note 4**: The acceptable country codes:

   | Country                               | Code | Country                   | Code | Country                               | Code | Country                     | Code | Country                       | Code        | Country                      | Code |
   |---------------------------------------|------|---------------------------|------|---------------------------------------|------|-----------------------------|------|-------------------------------|-------------|------------------------------|------|
   | ASCENSION ISLAND                      | `ac` | AFGHANISTAN               | `af` | ALAND                                 | `ax` | ALBANIA                     | `al` | ALGERIA                       | `dz`        | ANDORRA                      | `ad` |
   | ANGOLA                                | `ao` | ANGUILLA                  | `ai` | ANTARCTICA                            | `aq` | ANTIGUA AND BARBUDA         | `ag` | ARGENTINA REPUBLIC            | `ar`        | ARMENIA                      | `am` |
   | ARUBA                                 | `aw` | AUSTRALIA                 | `au` | AUSTRIA                               | `at` | AZERBAIJAN                  | `az` | BAHAMAS                       | `bs`        | BAHRAIN                      | `bh` |
   | BANGLADESH                            | `bd` | BARBADOS                  | `bb` | BELARUS                               | `by` | BELGIUM                     | `be` | BELIZE                        | `bz`        | BENIN                        | `bj` |
   | BERMUDA                               | `bm` | BHUTAN                    | `bt` | BOLIVIA                               | `bo` | BOSNIA AND HERZEGOVINA      | `ba` | BOTSWANA                      | `bw`        | BOUVET ISLAND                | `bv` |
   | BRAZIL                                | `br` | BRITISH INDIAN OCEAN TERR | `io` | BRITISH VIRGIN ISLANDS                | `vg` | BRUNEI DARUSSALAM           | `bn` | BULGARIA                      | `bg`        | BURKINA FASO                 | `bf` |
   | BURUNDI                               | `bi` | CAMBODIA                  | `kh` | CAMEROON                              | `cm` | CANADA                      | `ca` | CAPE VERDE                    | `cv`        | CAYMAN ISLANDS               | `ky` |
   | CENTRAL AFRICAN REPUBLIC              | `cf` | CHAD                      | `td` | CHILE                                 | `cl` | PEOPLE'S REPUBLIC OF CHINA  | `cn` | CHRISTMAS ISLANDS             | `cx`        | COCOS ISLANDS                | `cc` |
   | COLOMBIA                              | `co` | COMORAS                   | `km` | CONGO                                 | `cg` | CONGO (DEMOCRATIC REPUBLIC) | `cd` | COOK ISLANDS                  | `ck`        | COSTA RICA                   | `cr` |
   | COTE D IVOIRE                         | `ci` | CROATIA                   | `hr` | CUBA                                  | `cu` | CYPRUS                      | `cy` | CZECH REPUBLIC                | `cz`        | DENMARK                      | `dk` |
   | DJIBOUTI                              | `dj` | DOMINICA                  | `dm` | DOMINICAN REPUBLIC                    | `do` | EAST TIMOR                  | `tp` | ECUADOR                       | `ec` 	EGYPT | `eg`                         |
   | EL SALVADOR                           | `sv` | EQUATORIAL GUINEA         | `gq` | ESTONIA                               | `ee` | ETHIOPIA                    | `et` | FALKLAND ISLANDS              | `fk`        | FAROE ISLANDS                | `fo` |
   | FIJI                                  | `fj` | FINLAND                   | `fi` | FRANCE                                | `fr` | FRANCE METROPOLITAN         | `fx` | FRENCH GUIANA                 | `gf`        | FRENCH POLYNESIA             | `pf` |
   | FRENCH SOUTHERN TERRITORIES           | `tf` | GABON                     | `ga` | GAMBIA                                | `gm` | GEORGIA                     | `ge` | GERMANY                       | `de`        | GHANA                        | `gh` |
   | GIBRALTER                             | `gi` | GREECE                    | `gr` | GREENLAND                             | `gl` | GRENADA                     | `gd` | GUADELOUPE                    | `gp`        | GUAM                         | `gu` |
   | GUATEMALA                             | `gt` | GUINEA                    | `gn` | GUINEA-BISSAU                         | `gw` | GUYANA                      | `gy` | HAITI                         | `ht`        | HEARD & MCDONALD ISLAND      | `hm` |
   | HONDURAS                              | `hn` | HONG KONG                 | `hk` | HUNGARY                               | `hu` | ICELAND                     | `is` | INDIA                         | `in`        | INDONESIA                    | `id` |
   | IRAN, ISLAMIC REPUBLIC OF             | `ir` | IRAQ                      | `iq` | IRELAND                               | `ie` | ISLE OF MAN                 | `im` | ISRAEL                        | `il`        | ITALY                        | `it` |
   | JAMAICA                               | `jm` | JAPAN                     | `jp` | JORDAN                                | `jo` | KAZAKHSTAN                  | `kz` | KENYA                         | `ke`        | KIRIBATI                     | `ki` |
   | KOREA, DEM. PEOPLES REP OF            | `kp` | KOREA, REPUBLIC OF        | `kr` | KUWAIT                                | `kw` | KYRGYZSTAN                  | `kg` | LAO PEOPLE'S DEM. REPUBLIC    | `la`        | LATVIA                       | `lv` |
   | LEBANON                               | `lb` | LESOTHO                   | `ls` | LIBERIA                               | `lr` | LIBYAN ARAB JAMAHIRIYA      | `ly` | LIECHTENSTEIN                 | `li`        | LITHUANIA                    | `lt` |
   | LUXEMBOURG                            | `lu` | MACAO                     | `mo` | MACEDONIA                             | `mk` | MADAGASCAR                  | `mg` | MALAWI                        | `mw`        | MALAYSIA                     | `my` |
   | MALDIVES                              | `mv` | MALI                      | `ml` | MALTA                                 | `mt` | MARSHALL ISLANDS            | `mh` | MARTINIQUE                    | `mq`        | MAURITANIA                   | `mr` |
   | MAURITIUS                             | `mu` | MAYOTTE                   | `yt` | MEXICO                                | `mx` | MICRONESIA                  | `fm` | MOLDAVA REPUBLIC OF           | `md`        | MONACO                       | `mc` |
   | MONGOLIA                              | `mn` | MONTENEGRO                | `me` | MONTSERRAT                            | `ms` | MOROCCO                     | `ma` | MOZAMBIQUE                    | `mz`        | MYANMAR                      | `mm` |
   | NAMIBIA                               | `na` | NAURU                     | `nr` | NEPAL                                 | `np` | NETHERLANDS ANTILLES        | `an` | NETHERLANDS, THE              | `nl`        | NEW CALEDONIA                | `nc` |
   | NEW ZEALAND                           | `nz` | NICARAGUA                 | `ni` | NIGER                                 | `ne` | NIGERIA                     | `ng` | NIUE                          | `nu`        | NORFOLK ISLAND               | `nf` |
   | NORTHERN MARIANA ISLANDS              | `mp` | NORWAY                    | `no` | OMAN                                  | `om` | PAKISTAN                    | `pk` | PALAU                         | `pw`        | PALESTINE                    | `ps` |
   | PANAMA                                | `pa` | PAPUA NEW GUINEA          | `pg` | PARAGUAY                              | `py` | PERU                        | `pe` | PHILIPPINES (REPUBLIC OF THE) | `ph`        | PITCAIRN                     | `pn` |
   | POLAND                                | `pl` | PORTUGAL                  | `pt` | PUERTO RICO                           | `pr` | QATAR                       | `qa` | REUNION                       | `re`        | ROMANIA                      | `ro` |
   | RUSSIAN FEDERATION                    | `ru` | RWANDA                    | `rw` | SAMOA                                 | `ws` | SAN MARINO                  | `sm` | SAO TOME/PRINCIPE             | `st`        | SAUDI ARABIA                 | `sa` |
   | SCOTLAND                              | `uk` | SENEGAL                   | `sn` | SERBIA                                | `rs` | SEYCHELLES                  | `sc` | SIERRA LEONE                  | `sl`        | SINGAPORE                    | `sg` |
   | SLOVAKIA                              | `sk` | SLOVENIA                  | `si` | SOLOMON ISLANDS                       | `sb` | SOMALIA                     | `so` | SOMOA,GILBERT,ELLICE ISLANDS  | `as`        | SOUTH AFRICA                 | `za` |
   | SOUTH GEORGIA, SOUTH SANDWICH ISLANDS | `gs` | SOVIET UNION              | `su` | SPAIN                                 | `es` | SRI LANKA                   | `lk` | ST. HELENA                    | `sh`        | ST. KITTS AND NEVIS          | `kn` |
   | ST. LUCIA                             | `lc` | ST. PIERRE AND MIQUELON   | `pm` | ST. VINCENT & THE GRENADINES          | `vc` | SUDAN                       | `sd` | SURINAME                      | `sr`        | SVALBARD AND JAN MAYEN       | `sj` |
   | SWAZILAND                             | `sz` | SWEDEN                    | `se` | SWITZERLAND                           | `ch` | SYRIAN ARAB REPUBLIC        | `sy` | TAIWAN                        | `tw`        | TAJIKISTAN                   | `tj` |
   | TANZANIA, UNITED REPUBLIC OF          | `tz` | THAILAND                  | `th` | TOGO                                  | `tg` | TOKELAU                     | `tk` | TONGA                         | `to`        | TRINIDAD AND TOBAGO          | `tt` |
   | TUNISIA                               | `tn` | TURKEY                    | `tr` | TURKMENISTAN                          | `tm` | TURKS AND CALCOS ISLANDS    | `tc` | TUVALU                        | `tv`        | UGANDA                       | `ug` |
   | UKRAINE                               | `ua` | UNITED ARAB EMIRATES      | `ae` | UNITED KINGDOM (no new registrations) | `gb` | UNITED KINGDOM              | `uk` | UNITED STATES                 | `us`        | UNITED STATES MINOR OUTL.IS. | `um` |
   | URUGUAY                               | `uy` | UZBEKISTAN                | `uz` | VANUATU                               | `vu` | VATICAN CITY STATE          | `va` | VENEZUELA                     | `ve`        | VIET NAM                     | `vn` |
   | VIRGIN ISLANDS (USA)                  | `vi` | WALLIS AND FUTUNA ISLANDS | `wf` | WESTERN SAHARA                        | `eh` | YEMEN                       | `ye` | ZAMBIA                        | `zm`        | ZIMBABWE                     | `zw` |

### Test the proxy

```shell
while :; do curl -sx localhost:3128 ifconfig.io; echo ""; sleep 2; done
```

## Credit

At GitHub, there are many repos build Docker images to provide HTTP proxy connects to the Tor network.
The project is reinventing the wheels based on many of them.
Remarkably:
- [y4ns0l0/docker-multi-tor](https://github.com/y4ns0l0/docker-multi-tor) creates a setup with multiple pairs of Privoxy-Tor. Having no
  HAProxy-like dispatcher, each Privoxy expose itself to the host as a different TCP port.
- [mattes/rotating-proxy](https://github.com/mattes/rotating-proxy) does exactly the same job as this project. However,
    1. it utilizes [Polipo](https://www.irif.fr/~jch/software/polipo/) as the HTTP-SOCKS proxy adapter. Polipo ceased to be maintained on
       6 November 2016
    2. the base image is Ubuntu 14.04, which it too heavy for this case, and out-of-maintenance as well
    3. the main control logic is written in Ruby

## Bill-of-Material

<!--- Do not manually modify anything below this line! --->
<!--- BOM-starts --->
- alpine-3.21.3
- bash-5.2.37
- curl-8.12.1
- haproxy-3.0.10
- privoxy-3.0.34
- sed-4.9
- tor-0.4.8.16
<!--- BOM-ends. Document ends here too --->
