From: David Heidelberg <david@ixit.cz>
Date: Mon, 20 Jul 2026 12:13:12 +0200
Subject: [PATCH RFC] MAINTAINERS: Add Matrix channel to the NFC subsystem
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-nfc-matrix-v1-1-11cc79035472@ixit.cz>
X-B4-Tracking: v=1; b=H4sIALf0XWoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDcyMD3by0ZN3cxJKizArdlGQTiySDtGST5BQLJaCGgqLUtMwKsGHRSkF
 uzkqxtbUAQV2oMmEAAAA=
X-Change-ID: 20260720-nfc-matrix-dc48b0fc4cd8
To: Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 oe-linux-nfc@lists.linux.dev, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1231; i=david@ixit.cz;
 h=from:subject:message-id; bh=xv8y60McnQApKTGnwmwadUYgtutoYQCkFABtlPt2vGs=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqXfTAVwJi1QN2QN9lmm/bnANdhy9LEPAvKab2I
 lNdffYtPdeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCal30wAAKCRBgAj/E00kg
 ct37D/wJBjYoIpklUWWwW9AotU0UPjjIGei3ABhEHZRrDSB7bONMO3m5avW2DU3QIurnNB4tfPV
 n7buVoHkfq3o4DNtUQhknImbzZDjD0S+00EVi9lvGUX2a+rWkooRLTr6xlyCJLTK0SMpQF3F8sx
 IWlLTftKqb3yWdttbDHvkS16hisP+VEIoNoG2Yq/dl67SGbJRk4QLYIa0acdfN/tpenUhvjoT2x
 9YCsAHp685bNVxAYiUNr+aclQaLqV7JvI4sCrF5A79zw/v2ynchEqgzyu+dojTsSauAESaxC/Rp
 3um+FD3FuQVJ8w3Lm9VUq8IoVbgGmAYWewuuuAMrbg9DzT74RHxVmMc/6FKOSRcWILh6/bCEcMD
 toI2ZOgfwYsSFJxavgcVLy/N/+Ddn9dJxCfkV2ZcZpIWtC9H2sL8ot4R6VgcoowhsArMJ9toEpI
 svtMrF/DFQhDi1+3EZrP0FCmYu00XAk0bjGr61o31SD/ptVQAhjnFMytvZznjzjWE8euhVsdeSG
 YEPdSMUc8EbWEkASWonHc+x8NFyuq6rnxjaMfZKOvd76ngk9p+rmbOd053E8/XwrJYzT7OLpPdq
 teqLcKwewXyxLpHWsvn8M2masVmOGcQ3ZgePHBxOlaSncAWB/FNxXg+5znY7evzVmRk/K37KH04
 iPiA6cb5bEAngvA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We use the Matrix channel already, let's share the information.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
This is the first Matrix channel added, so I'm sending it aside of my
tree to estabilish the format of the channel.

We could have something like

matrix://#linux-nfc:ixit.cz or full URL as we use now.

I would like to hear what you think! :)
---
 MAINTAINERS | 1 +
 1 file changed, 1 insertion(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 52e2c22d533a2..6828127e66078 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -19149,16 +19149,17 @@ L:	netdev@vger.kernel.org
 S:	Supported
 F:	Documentation/networking/net_failover.rst
 F:	drivers/net/net_failover.c
 F:	include/net/net_failover.h
 
 NFC SUBSYSTEM
 M:	David Heidelberg <david@ixit.cz>
 L:	oe-linux-nfc@lists.linux.dev
+C:	https://matrix.to/#/#linux-nfc:ixit.cz
 S:	Maintained
 T:	git https://codeberg.org/linux-nfc/linux.git
 F:	Documentation/devicetree/bindings/net/nfc/
 F:	drivers/nfc/
 F:	include/net/nfc/
 F:	include/uapi/linux/nfc.h
 F:	net/nfc/
 

---
base-commit: 0718283ab28bc3907e10b61a6b4be6fefa1cbb2f
change-id: 20260720-nfc-matrix-dc48b0fc4cd8

Best regards,
-- 
David Heidelberg <david@ixit.cz>

