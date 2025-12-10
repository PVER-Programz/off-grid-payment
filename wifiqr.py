def wifiqr():
	import tkinter as tk
	from tkinter import ttk
	from PIL import Image, ImageTk
	import qrcode
	import io
	from ip4get import get_ipv4

	def generate_qr():
		ssid = ssid_var.get()
		password = password_var.get()

		wifi_type = "WPA" if password else "nopass"
		wifi_str = f"WIFI:T:{wifi_type};S:{ssid};P:{password};IP:{get_ipv4()};"

		# Generate QR image in memory
		qr_img = qrcode.make(wifi_str)
		buffer = io.BytesIO()
		qr_img.save(buffer, format="PNG")
		buffer.seek(0)

		# Convert to Tkinter image and display
		img = Image.open(buffer)
		img = img.resize((200, 200))
		tk_img = ImageTk.PhotoImage(img)
		qr_label.config(image=tk_img)
		qr_label.image = tk_img  # keep a reference

	def on_change(*args):
		generate_qr()

	def toggle_password():
		if password_entry.cget("show") == "":
			password_entry.config(show="*")
			toggle_btn.config(text="Show")
		else:
			password_entry.config(show="")
			toggle_btn.config(text="Hide")

	# Create window
	root = tk.Tk()
	root.title("Wi-Fi QR Generator")
	root.geometry("320x420")

	# Variables with default values
	ssid_var = tk.StringVar(value="VITC-EVENT")
	password_var = tk.StringVar(value="Eve@09&10#$")

	ssid_var.trace_add("write", on_change)
	password_var.trace_add("write", on_change)

	# SSID input
	ttk.Label(root, text="SSID:").pack(pady=(10,0))
	ssid_entry = ttk.Entry(root, textvariable=ssid_var, width=30)
	ssid_entry.pack(pady=5)

	# Password input + toggle
	ttk.Label(root, text="Password:").pack(pady=(10,0))
	frame_pw = ttk.Frame(root)
	frame_pw.pack(pady=5)

	password_entry = ttk.Entry(frame_pw, textvariable=password_var, width=23, show="*")
	password_entry.pack(side="left")

	toggle_btn = ttk.Button(frame_pw, text="Show", command=toggle_password, width=6)
	toggle_btn.pack(side="left", padx=5)

	# QR display area
	qr_label = ttk.Label(root)
	qr_label.pack(pady=20)

	# Generate initial QR
	generate_qr()

	root.mainloop()


wifiqr()