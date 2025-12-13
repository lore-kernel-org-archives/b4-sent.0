From: Zhaoming Luo <zhml@posteo.com>
Date: Sat, 13 Dec 2025 23:04:11 +0800
Subject: [PATCH v2] dt-bindings: ufs: Fix a grammar error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251213-fix-minor-grammar-err-v2-1-b32be57caa13@posteo.com>
X-B4-Tracking: v=1; b=H4sIAGqAPWkC/x2MQQqAMAzAviI9W9gqKvoV8TBcpz1sSgciDP/u8
 BhIUiCzCmeYmwLKt2Q5UwVqG9gOl3ZG8ZWBDPWWbIdBHoySTsVdXYxOkVVxGL01W6DgJw+1vZS
 r+H+X9X0/tnyRPWcAAAA=
X-Change-ID: 20251213-fix-minor-grammar-err-67d10cf2fd9d
To: Alim Akhtar <alim.akhtar@samsung.com>, 
 Avri Altman <avri.altman@wdc.com>, Bart Van Assche <bvanassche@acm.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-scsi@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Zhaoming Luo <zhml@posteo.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1440; i=zhml@posteo.com;
 h=from:subject:message-id; bh=fori8aM450W7B3/fTbmPAYSMy/U8i5ZeqbO0a1qO7mc=;
 b=owGbwMvMwCWW8vrrboHTHcGMp9WSGDJtG1o+qz+J/6IurKsm+/8KI3PRDKb3Ka2T9+Y5iee4R
 7hHPzzWMZGFQYyLwVJMkcU57kHABd8el8DWY54wc1iZQIZIizQwAAELA19uYl6pkY6Rnqm2oZ6h
 oQ6QycDFKQBT/bqJkWHj3Nv8HTM7TP65uV5R3PjMnicx65JYDeeyxaac3WsqNv9n+GcyIz4uR0p
 63bmJ/+o3LzqQFPR0CpujSvcOqebQa0E/vrMBAA==
X-Developer-Key: i=zhml@posteo.com; a=openpgp;
 fpr=435EE050D04D8C445185C64964EBF5BB10CB8853
X-Endpoint-Received: by B4 Relay for zhml@posteo.com/default with auth_id=576
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix a minor grammar error.

Signed-off-by: Zhaoming Luo <zhml@posteo.com>
---
Changes from v1[0]:
- The subject prefixes match the subsystem as suggested in the
  documentation[1].
- The necessary To/Cc entries are included.

Thanks to Krzysztof Kozlowski for pointing out the errors and providing
helpful information about how to fix them.

[0]: https://lore.kernel.org/linux-scsi/20251212131112.5516-1-zhml@posteo.com/
[1]: https://www.kernel.org/doc/html/latest/devicetree/bindings/submitting-patches.html#i-for-patch-submitters
---
 Documentation/devicetree/bindings/ufs/ufs-common.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/ufs/ufs-common.yaml b/Documentation/devicetree/bindings/ufs/ufs-common.yaml
index 9f04f34d8..efeae8f3d 100644
--- a/Documentation/devicetree/bindings/ufs/ufs-common.yaml
+++ b/Documentation/devicetree/bindings/ufs/ufs-common.yaml
@@ -48,7 +48,7 @@ properties:
     enum: [1, 2]
     default: 2
     description:
-      Number of lanes available per direction.  Note that it is assume same
+      Number of lanes available per direction.  Note that it is assumed same
       number of lanes is used both directions at once.
 
   vdd-hba-supply:

---
base-commit: 9d9c1cfec01cdbf24bd9322ed555713a20422115
change-id: 20251213-fix-minor-grammar-err-67d10cf2fd9d

Best regards,
-- 
Zhaoming Luo <zhml@posteo.com>

