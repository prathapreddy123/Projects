#$ pip install pycrypto
from Crypto.Cipher import AES
import base64
import os,sys
import argparse

# the block size for the cipher object; must be 16, 24, or 32 for AES
BLOCK_SIZE = 16

# the character used for padding--with a block cipher such as AES, the value
# you encrypt must be a multiple of BLOCK_SIZE in length.  This character is
# used to ensure that your value is always a multiple of BLOCK_SIZE
PADDING = '{'

# one-liner to sufficiently pad the text to be encrypted
pad = lambda s: s + (BLOCK_SIZE - len(s) % BLOCK_SIZE) * PADDING

# generate a random secret key
secret =  '{random{random{{'

# create a cipher object using the random secret
cipher = AES.new(secret)


def encrypt(value):
	return base64.b64encode(cipher.encrypt(pad(value)))

def decrypt(value):
	return cipher.decrypt(base64.b64decode(value)).decode().rstrip(PADDING) 

def parseargs():
	parser = argparse.ArgumentParser()  #takes sys.argv as default program
	#parser.add_argument('-h', '--help')
	parser.add_argument('-o', '--operation', dest='operation', action='store',choices=['encrypt', 'decrypt'])
	parser.add_argument('-v', '--value', dest='value', action='store')
	args = None
	try:
		args = parser.parse_args()
		if args.operation == None or args.value == None:
			parser.print_help()
			args = None
	except:
		pass

	return args

def main():
	arguments = parseargs()
	if arguments != None:
		try:
			returnval = encrypt(arguments.value) if arguments.operation == 'encrypt' else decrypt(arguments.value)
			print("{}ed value is {}".format(arguments.operation,returnval))
		except:
			print("Error occurred:" + sys.exc_info()[1])


if __name__ == '__main__':
	'''
	This script is basically used for encrypting and decrypting sensitive information with same secret key and uses pycrypto package.
	Script exepects operation type (encrypt/decrypt) and value as arguments
	usage: encryptdecrypt.py -o {encrypt,decrypt}] -v VALUE
	'''
	main()