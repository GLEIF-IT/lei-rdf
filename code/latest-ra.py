#!/opt/python3/bin/python3

# Copyright (c) Data.world, 2020
# Author Dashiel Lopez Mendez
# Licensed under MIT License

# Fetches the latest URI for the Registration Authorities List
from bs4 import BeautifulSoup
import requests


ra_url = 'https://www.gleif.org/en/about-lei/code-lists/gleif-registration-authorities-list'

r = requests.get(ra_url)
r.raise_for_status()

soup = BeautifulSoup(r.content, 'html.parser')

# searches for a single URL with 'csv' in the href
csv_link = soup.select_one('a[href*=csv]')
uri = csv_link.get('href')

print(f'export RA={uri}')
