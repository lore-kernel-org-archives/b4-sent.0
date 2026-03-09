From: Carl Lee <carl.lee@amd.com>
Subject: [PATCH 0/2] ARM: dts: aspeed: anacapa: add eeprom devices
Date: Mon, 09 Mar 2026 11:29:26 +0800
Message-Id: <20260309-arm-dts-aspeed-anacapa-add-eeprom-device-v1-0-45092310e0e6@amd.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJY+rmkC/x2NwQqDMBAFf0X23IWoKLS/Unp4Js82h8awKUUQ/
 71Lj8PAzCGNltnk1h1i/OaWt+LQXzqJL5QnNSdnGcIwhzFcFfbW9GmKVsmkKIioUKSkZLXNrWc
 iFT2wMMwYp0U8V41r3v+r++M8f8Xs9lx6AAAA
X-Change-ID: 20260309-arm-dts-aspeed-anacapa-add-eeprom-device-a1aabe06a35b
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 carl.lee@amd.com, peter.shen@amd.com, colin.huang2@amd.com
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773026981; l=628;
 i=carl.lee@amd.com; s=20260203; h=from:subject:message-id;
 bh=GaoP8wcFVTkbA0qAqdRsL25+1PTp6d7J/ewviONVA+o=;
 b=kgrps2Go1O4NvQWUFzsxLNEgYXY5NUMhGVNxD99zrowxmzORxAcbs5rIdv1EZnF/n4UTaLfVN
 vEF+OVFHqZ9AJqv/iM04dPXj3sUtCJWN4uWI6C3XLSaA+E4Ohews4Aa
X-Developer-Key: i=carl.lee@amd.com; a=ed25519;
 pk=pyq7QaQvoxMg806KVkRwpCbiah+7ncWr4MBpK1AEyjA=
X-Endpoint-Received: by B4 Relay for carl.lee@amd.com/20260203 with auth_id=623
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add eeprom device nodes used to store FRU data for the PRoT
module and NFC adapter board on Anacapa platform.

Signed-off-by: Carl Lee <carl.lee@amd.com>
---
Carl Lee (2):
      ARM: dts: aspeed: anacapa: Add eeprom device node for PRoT module
      ARM: dts: aspeed: anacapa: Add eeprom device node for NFC adaptor board

 arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts | 10 ++++++++++
 1 file changed, 10 insertions(+)
---
base-commit: a0ae2a256046c0c5d3778d1a194ff2e171f16e5f
change-id: 20260309-arm-dts-aspeed-anacapa-add-eeprom-device-a1aabe06a35b

Best regards,
-- 
Carl Lee <carl.lee@amd.com>

