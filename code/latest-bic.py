#!/opt/python3/bin/python3

# Copyright (c) Data.world, 2020
# Author Dashiel Lopez Mendez
# Licensed under MIT License

# Fetches the latest URI for the Business Identifier Codes
from bs4 import BeautifulSoup
import requests


bic_url = 'https://www.gleif.org/en/lei-data/lei-mapping/download-bic-to-lei-relationship-files'

r = requests.get(bic_url)
r.raise_for_status()

soup = BeautifulSoup(r.content, 'html.parser')

# searches for the table of files, and then the first URL, anticipating that
# it's the newest
table = soup.find('tbody')
top_table_entry = table.find_all('tr')[0]
csv_link = top_table_entry.select_one('a')
uri = csv_link.get('href')

print(f'export BIC={uri}')
