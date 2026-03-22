From: David Heidelberg <david@ixit.cz>
Subject: [PATCH QUESTION 0/2] NFC support in Linux (and support for
 Qualcomm SDM845 devices)
Date: Sun, 22 Mar 2026 15:24:18 +0100
Message-Id: <20260322-oneplus-nfc-v1-0-5f22f544f0e2@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJL7v2kC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDQ0ML3fy81IKc0mLdvLRk3WQDg9Q0w+SUtETLJCWgjoKi1LTMCrBp0Uq
 Boa7BIZ7+fkqxtbUAFlwnv2cAAAA=
X-Change-ID: 20251118-oneplus-nfc-c00ef1cdfa9b
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>, 
 biemster <l.j.beemster@gmail.com>, netdev@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, oe-linux-nfc@lists.linux.dev, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1991; i=david@ixit.cz;
 h=from:subject:message-id; bh=0y+vz9QItdufZS4Gg1aj8uk09vnC7uOD1Z32a7tIeRg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpv/uUtZf7rj034FIS1wsfZrfec7TNLugbDYF7R
 C+mgBKhrreJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCab/7lAAKCRBgAj/E00kg
 cuV9EADQlJ4AcLuzCdke6vz8uKtFi3LaQOIqic0KyvwHlDp+iSQqpo+q4muU3H4juTjatvmVK5G
 XMHc4TL31G5HNqmJhWqmmySxXnHDOiYu5Ql7oJ1WonCv1bmHUaJWMXwIWDxM0cHpPZdx6CvqbWJ
 aMlqrxyWAHv6L/bFwtzWemA6ksOrWhxf4Ni+kR6PGHlx6VxbeSzK1g2SM5L4S8MrBFFpmcRpwV5
 TYQobX1Yc4i6i+4R9QBkfQ12stVgfzmDahkAYg+zLOlR1n15tyjiIYqcDrtcVhM00s4i29vlwUT
 ftQLSQfDTkO79tZxrwEjQEpJSSRfXd2Zm8F/junJvqicQe620B7/kuuC18rRWAMOnkgMfKk/g35
 HAS9Ix2yNCR33d6LPWnP6/ZUSuoV0FtW9LlynGRngPw6Gj3xg6Jlgew6V+f78niy+ea/V9TOt/Q
 YFaO3F2u8vliJgkXY2W+xCbC7j58OVHU9v21SN9soCjkVnQrv7QKryuM5Wjmg7mzKwFmKwJ80mK
 YXD9TA6CGwdYTQgXRqBCdUwTBomwtpEpnj6ytQPxKEviwR/kYO9uk/K8BrUBbXFQQbLqKkd0zK2
 oFxytPIG7qMZ/Y7WvQYg8CpqQtMlCllYog9Lg9Es7ScX/LRKgoNRQm9EjfppdniQJRlmPUj6QfI
 aMOYx1GrDk8NzXw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There isn't upstream driver.

I'm openining this as a starter. We need a NFC drivers I assume. I tried
quick check, but both of NFC drivers register

nfc: nfc_init: NFC Core ver 0.1
NET: Registered PF_NFC protocol family

but efficiently does nothing. In the See section, there are some ways
how to make NFC work, but rely on patched vendor libs, missing updates
etc.

1. What hardware is present on Snapdragon 845, is there some
   documentation? It seems that both sdm845 devices has almost identical
   setup, thus it's NFC solution integrated? @Qualcomm

2. What's the right approach to continue? Should we upstream these
   definitions and then start developing user-space stack? @netdev (I
   see orphaned)

Since looking at NFC mailing list (oe-linux-nfc) and seeing it's pretty
much dead, would be cool to revive it.

Also there is some effort from Arch people [1], but likely without clean
path to mainline.

Can we revieve the NFC effort? I'm offering limited maintanance (in case
people would send patches).

See:
 - https://gitlab.com/sdm845-mainline/linux/-/merge_requests/62
 - https://github.com/NXPNFCLinux/linux_libnfc-nci/
   - https://github.com/biemster/pmos-openbox-conky/blob/main/libnfc-nci.patch
   - https://github.com/biemster/pmos-openbox-conky/blob/main/nfctest.patch
   - pull request
   - full of hacks

 - [1] https://github.com/zmr-233/linux-nxp-nfc-fix

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (1):
      arm64: dts: qcom: sdm845-shift-axolotl: Enable NFC

biemster (1):
      arm64: dts: qcom: sdm845-oneplus: Enable NFC

 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 32 +++++++++++++++++++++
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts  | 33 ++++++++++++++++++++++
 2 files changed, 65 insertions(+)
---
base-commit: 785f0eb2f85decbe7c1ef9ae922931f0194ffc2e
change-id: 20251118-oneplus-nfc-c00ef1cdfa9b

Best regards,
-- 
David Heidelberg <david@ixit.cz>

