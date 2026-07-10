From: Chen Linxuan <me@black-desk.cn>
Date: Fri, 10 Jul 2026 15:22:13 +0800
Subject: [PATCH] b4: include change-id in cover template
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-add-change-id-to-b4-template-v1-1-1bd37a25064e@black-desk.cn>
X-B4-Tracking: v=1; b=H4sIAKSdUGoC/z3MTQqDMBBA4avIrDswRmmwVyldRDPRKfWHJIog3
 t2o0OXHg7dBYC8c4JVt4HmRIOOQkD8yaDoztIxik0GRepLOCY21+C8YR6xLjNxPPxMZXeWsoqr
 QpDSkxeTZyXrt35/bYa6/3MTzCft+ALVVBJ+AAAAA
X-Change-ID: 20260710-add-change-id-to-b4-template-f9fd20937027
To: git@vger.kernel.org
Cc: Patrick Steinhardt <ps@pks.im>, Junio C Hamano <gitster@pobox.com>, 
 Chen Linxuan <me@black-desk.cn>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1265; i=me@black-desk.cn;
 h=from:subject:message-id; bh=HuviA3htWPIWMaE9A8vkJhpFqEe5gi8rdGO5ZW4cI1o=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBqUJ2lUMR26aObJXj05ciU5Hw4Y8fKpE7espKtp
 srPryG7qvaJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCalCdpQAKCRB2HuYUOZmu
 iz6gD/sHBmhNlHOvipXHFAXMpfmx71IcfCGZ2TzE9XTQQrX0sGy53+4zbijpRbwUxLyw/fKLi+e
 TuKBPHkXWuvqXhwgM3ycMjGrckAavYuWq5d51gb6mpy/GhJYyOX8V3IjJFkj5Yt50Q1yOpd5SZY
 38/hkt9P/maNAWcNv/VT7Sfut3/XPkx+Cw9LeAyJOP6PyrLSPWR9Pg4Ktm8l0Ql+D0P4+rUijFu
 irIu00S0wIDQ5R+HD6GRFh74ZCn1JcfNED7VLdHybJMNZNdxzei93P0regAzndJvYKQjvE412+y
 V/PR0K5vfz+D8iI4Xrgei8MLlAjrfoO+qsWvqb/CQGukfGR6pU9mpgVH+YeCX3RRSOLmC7Nm2iQ
 0Dqvx1z5qjzABkzcODwHWzTWh8OskM2DNNgSt/w3P/GOPc45Rh4Dnh0Xa/SLF516awpxMKV6Nm3
 0Jkmi/CvDMFdHrkOVJhE9OMlOsthxSJS+geMYCKkbznSHsAX0BjssJRqeRIZB5A/bhJIh1ckGNv
 IPmAA7Pi4LOqP6MiGeMZ2JGRlL8pOGDKFRpScbIipBoJ5X5R4kKn/KbEtoB3wjdVzqSXrWGqQOp
 ZSNtzV6MwgR99pqVJ3XVayeXaNlh6hgIfKBXxR2i5YbBjoBIauhTbXazQT+ui5dvxhlFvW4xPiT
 pGHaZANG6kSnz6A==
X-Developer-Key: i=me@black-desk.cn; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for me@black-desk.cn/default with auth_id=573
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With b4 0.15.2, I hit a local failure after sending a series with the
in-tree cover template.  The generated sent/<change-id>-vN tag contained
base-commit, but did not contain change-id, and later b4 commands failed
when trying to read it:

  CRITICAL: Tag sent/... does not contain change-id info

Looking at b4's source, the sent tag message is derived from the rendered
cover letter.  The same code later parses that tag and expects both
base-commit and change-id to be present.  The default b4 cover template
has both trailers, but our in-tree template only has base-commit.

Add the missing change-id trailer next to base-commit so sent tags
produced from the project template remain readable by b4's reroll and
comparison logic.

Signed-off-by: Chen Linxuan <me@black-desk.cn>
---
 .b4-cover-template | 1 +
 1 file changed, 1 insertion(+)

diff --git a/.b4-cover-template b/.b4-cover-template
index ab864933b5c8..8168d8a10b3a 100644
--- a/.b4-cover-template
+++ b/.b4-cover-template
@@ -8,4 +8,5 @@ ${diffstat}
 ${range_diff}
 ---
 base-commit: ${base_commit}
+change-id: ${change_id}
 ${prerequisites}

---
base-commit: f60db8d575adb79761d363e026fb49bddf330c73
change-id: 20260710-add-change-id-to-b4-template-f9fd20937027

