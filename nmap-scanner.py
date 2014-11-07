#!/usr/bin/env python



import argparse
from libnmap.process import NmapProcess
from libnmap.parser import NmapParser, NmapParserException
from time import sleep

targets = "192.168.1.40"
options = "-sV -p 445"


def do_scan(targets, options):
	parsed = None
	nm = NmapProcess(targets, options)
	rc = nm.run()
	if rc != 0:
		print(" [-] Nmap scan failed: {}".format(nm.stderr))
	
	print(str(nm.stdout))
	
	try:
		parsed = NmapParser.parse(nm.stdout)
	except NmapParserException as e:
		print(" [-] Exception raised while parsing scan: {}".format(e.msg))
	
	return parsed
	
	
def print_scan(nmap_report):
	print("Starting Nmap {} ( http://nmap.org ) at {}".format(
		nmap_report.version,
		nmap_report.started))
	
	for host in nmap_report.hosts:
		if len(host.hostnames):
			tmp_host = host.hostnames.pop()
		else:
			tmp_host = host.address
	
		print("Nmap scan report for {0} ({1})".format(tmp_host, host.address))
		print("Host is {}.\n".format(host.status))
		print("{0:^10} {1:^10} {2:^12}".format('PORT', 'STATE', 'SERVICE'))
	
		for serv in host.services:
			pserv = ("  {0:s}/{1:<6s} {2:<10} {3:<8}".format(
				str(serv.port),
				serv.protocol,
				serv.state,
				serv.service))
		
			if len(serv.banner):
				pserv += " ({})".format(serv.banner)
			print(pserv)
	print('\n{}'.format(nmap_report.summary))






# scan results
# XML output - NmapProcess.stdout
# string, text errors - NmapProcess.stderr


if __name__ == '__main__':
	parser = argparse.ArgumentParser(description="Nmap Scan integration")
	parser.add_argument("-t", help="Target(s) to scan")
	args = parser.parse_args()
	
	if args.t:
		targets = args.t
		
	#nm = NmapProcess(target, options="-p 445")
	#rc = nm.run()
	
	report = do_scan(targets, options)
	if report:
		print_scan(report)
	else:
		print("No results returned")
