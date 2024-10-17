From: Eric Long <i@hack3r.moe>
Date: Thu, 17 Oct 2024 23:33:17 +0800
Subject: [PATCH nftables] libnftables-json: fix raw payload expression
 documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241017-libnftables-json-doc-fix-v1-1-c0d2efca1ab2@hack3r.moe>
X-B4-Tracking: v=1; b=H4sIADwuEWcC/zWMQQqEMAwAvyI5G7ChIvgV8VDbqBFppRFZEP++R
 fA4AzM3KGdhhb66IfMlKikWMHUFfnVxYZRQGKghaxrT4S5TnE837ay4aYoYksdZfshEtnVkPQc
 PJT8yF/2uB/gSGJ/nD0+tDXN0AAAA
X-Change-ID: 20241017-libnftables-json-doc-fix-e2245a24cedc
To: netfilter-devel@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=978; i=i@hack3r.moe;
 h=from:subject:message-id; bh=8G2jiRNCYmstnPIa64oo9+zrrbBcL2qkry/1/TIQ7H8=;
 b=owGbwMvMwCUWYb/agfVY0D7G02pJDOmCeo5b1JvS4kKdZ1qmvJVLu34pLOW1cMj64ObI1OT8L
 Tmzl4t3lLIwiHExyIopsmw5/EctQb970xLuOeUwc1iZQIYwcHEKwERqXzIyLPtkfNjtx+LMuWW5
 CcdnP7i644zW9Ovu5aK6aSsvq5cYvWJkOLY359v6Uq3aj9N3KmyaZpDsduRqzKQHah55ZzRuNvF
 sZAEA
X-Developer-Key: i=i@hack3r.moe; a=openpgp;
 fpr=3A7A1F5A7257780C45A9A147E1487564916D3DF5
X-Endpoint-Received: by B4 Relay for i@hack3r.moe/default with auth_id=225
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Raw payload expression accesses payload data in bits, not bytes.

---
 doc/libnftables-json.adoc | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/doc/libnftables-json.adoc b/doc/libnftables-json.adoc
index a8a6165fde59d419f1ec7a1fa904e1491fe15284..2f29ac0436280719e50016ee92a6b78605894831 100644
--- a/doc/libnftables-json.adoc
+++ b/doc/libnftables-json.adoc
@@ -1182,7 +1182,7 @@ ____
 
 Construct a payload expression, i.e. a reference to a certain part of packet
 data. The first form creates a raw payload expression to point at a random
-number (*len*) of bytes at a certain offset (*offset*) from a given reference
+number (*len*) of bits at a certain offset (*offset*) from a given reference
 point (*base*). The following *base* values are accepted:
 
 *"ll"*::

---
base-commit: ff0846371c0c1cca41fd61ef2c481248684b8aa9
change-id: 20241017-libnftables-json-doc-fix-e2245a24cedc

Best regards,
-- 
Eric Long <i@hack3r.moe>

