From: Maud Spierings <maud_spierings@hotmail.com>
Subject: [PATCH 0/2] arm64: dts: qcom: x1e80100-vivobook-s15: Add usb a and
 sd-card reader
Date: Sun, 19 Jan 2025 15:50:50 +0100
Message-Id: <20250119-usb_a_micro_sd-v1-0-01eb7502ae05@hotmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEoRjWcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDQ0NL3dLipPjE+NzM5KL8+OIUXZNkE3Oz1ERzM8skQyWgpoKi1LTMCrC
 B0bG1tQAlmMaJYAAAAA==
X-Change-ID: 20250119-usb_a_micro_sd-4c476ea769b1
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1737298255; l=2119;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=AX5VJfJx56rXXVQSO+9NkM/PmYBy4kqrprJ7LvyVVn0=;
 b=kx/NfvnPmOYQw+KpxvPD8lyMcKVtHa8QDaSo3OM8h2zwU8uwivmDT0bxQEI/CA5XMHdoeVvc2
 JQzN9bV4x4/BkBEjSiPAwWZfjZRFWcLOhAvLESNheEu/3pFxhs8uSgf
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Asus Vivobook s15 has 2 5gbps usb A ports on the right side which
are controlled by the usb_mp controller enable them and the retimers
required.

There is also a micro sd-card reader on the left side below the two
usb-c ports, this one is attached to the usb_2 controller. Enable it and
the retimer to enable the micro sd-card reader.

The micro sd-card reader seems to have so interesting behaviour, on my
machine and someone elses it kind of half works, but not really, the
same under windows, unusable. Either we both got unlucky with a hardware
defect or there is something else going on, however two other people did
succesfully test it, one of which on (free?)bsd instead of linux even.
One hypothesis is that this area is where the charging circuitry is,
which gets *very* hot while charging and might damage this bit of
hardware. However this is very much speculation and not based on
anything concrete.

Symptoms of dysfunctional sd-card reader:
The sd card will get detected, a usb device will appear as "Genesys Logic
STORAGE DEVICE" 05e3:0747

log:
[ 2456.648075] usb 1-1: new high-speed USB device number 3 using xhci-hcd
[ 2456.792703] usb-storage 1-1:1.0: USB Mass Storage device detected
[ 2456.795530] scsi host0: usb-storage 1-1:1.0
[ 2457.840518] scsi 0:0:0:0: Direct-Access     Generic  MassStorageClass
2402 PQ: 0 ANSI: 6
[ 2458.072281] sd 0:0:0:0: [sda] Media removed, stopped polling
[ 2458.073001] sd 0:0:0:0: [sda] Attached SCSI removable disk

/dev/sda will appear, but it will not do anything, fdisk rejects it etc

Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
Maud Spierings (2):
      arm64: dts: qcom: x1e80100-vivobook-s15: Enable USB-A ports
      arm64: dts: qcom: x1e80100-vivobook-s15: Enable micro-sd card reader

 .../boot/dts/qcom/x1e80100-asus-vivobook-s15.dts   | 142 ++++++++++++++++++++-
 1 file changed, 141 insertions(+), 1 deletion(-)
---
base-commit: 0907e7fb35756464aa34c35d6abb02998418164b
change-id: 20250119-usb_a_micro_sd-4c476ea769b1

Best regards,
-- 
Maud Spierings <maud_spierings@hotmail.com>

