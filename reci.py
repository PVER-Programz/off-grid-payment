import requests
'''
# Pay to shopkeeper
url = "http://172.16.45.124:5000/pay"
data = {'username': 'dharmendresh', 'amount':100}
response = requests.post(url, json=data)
print(response.status_code)
print(response.text)
'''
# Recieving Request
url = "http://172.16.45.124:5000/untransact"
data = {'payee': 'pram'}
response = requests.post(url, json=data)
print(response.status_code)
print(response.text)

'''
# Pay to friend
url = "http://172.16.45.124:5000/transact"
data = {'from': 'sarva', 'to':'pram', 'amount':40}
response = requests.post(url, json=data)
print(response.status_code)
print(response.text)

# Getting shop name
url = "http://172.16.45.124:5000/merchantname"
response = requests.get(url)
print(response.status_code)
print(response.text)
'''