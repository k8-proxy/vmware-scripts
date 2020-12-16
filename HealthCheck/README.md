# Health Check script

This script can be used to check Health of automaticly created solutions in pipelines e.g. OVA Creation. This can be also used as a standalone solution.

### Features 
* ping check
* TCP port check
* http/https code status check (eg. 200)
* http/https return string check

### Usage

Edit config.yml with checks.
run using:
```bash
python3 pyCheck.py
```
If you want to display how many checks fails use:
```bash
echo $?
```
