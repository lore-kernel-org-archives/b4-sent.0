From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Fri, 09 Dec 2022 16:47:36 -0500
Subject: [PATCH RFC foobar v3] Makefile: pirate > ninja
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20220921-single-patch-v3-1-9cde759c1cbe@linuxfoundation.org>
X-B4-Tracking: v=1; b=H4sIAPisk2MC/33OTQ7CIBAF4KsY1mJgqG1x5T2MC/5aSAgYaImm6 d2duFZXkzfJ+2Y2Ul0JrpLLYSPFtVBDThjE8UCMV2l2NFjMBBgAk8BpDWmOjj7UYjzlnekZqMlo KQlWtKqO6qKS8VhKa4y49KEuubw+JxrHcfuhNU45FedRqmEQwrL+GkNan1Nek1ULPnbKZSZ3JBv 8YwCZ0cgOdDdIsPo7s+/7G/hHMBn+AAAA
To: Dev Nuller <devnull@kernel.org>, Castor Anxieux <k@castoranxieux.ca>, Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Cc: Kay Arr <konstantin.ryabitsev@linux.dev>
X-Mailer: b4 0.11.0-dev-b33dc
X-Developer-Signature: v=1; a=openpgp-sha256; l=1181;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=ZH2YCs2zT9RQFoQSDes8XrKFFrwa39ukT8+Rd9UYDKs=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJInr2X9zp/hm5n7Ljn4/UTHee8qFuce1bTkVLjiKnaw409y
 WKJhRykLgxgXg6yYIkvZvthNQYUPPeTSe0xh5rAygQxh4OIUgIlMyWD471wvbrSAa14JN+e/P27PTs
 mwG3s0lT3m/bT1zCIVgQRND4b/FfsPcop/n8x7gm3ZncuRfPcnaPSJLnv1y3sqg7/dnAv2nAA=
X-Developer-Key: i=konstantin@linuxfoundation.org; a=openpgp;
 fpr=DE0E66E32F1FDD0902666B96E63EDCA9329DD07E
X-Endpoint-Received: by B4 Submission Endpoint for konstantin@linuxfoundation.org/default with auth_id=3
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Pirates are always better than ninjas.

Cc: Kay Arr <konstantin.ryabitsev@linux.dev>
Signed-off-by: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
---
Here we include some extra info about the series.
---
Changes in v3:
- No changes, just need a new revision
- Link to v2: https://lore.kernel.org/r/20220921-single-patch-v2-1-8c942b4792db@linuxfoundation.org

Changes in v2:
- No changes, just need a new revision
- Link to v1: https://lore.kernel.org/r/20220921-single-patch-v1-1-3589a7733d06@linuxfoundation.org

Changes in v1:
- Taken from junky stuff
---
 Makefile | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Makefile b/Makefile
index 0992f827888d..c61b4ecd6a7c 100644
--- a/Makefile
+++ b/Makefile
@@ -3,7 +3,7 @@ VERSION = 6
 PATCHLEVEL = 1
 SUBLEVEL = 0
 EXTRAVERSION = -rc8
-NAME = Hurr durr I'ma ninja sloth
+NAME = Hurr durr I'ma pirate sloth
 
 # *DOCUMENTATION*
 # To see a list of typical targets execute "make help"

---
base-commit: 76dcd734eca23168cb008912c0f69ff408905235
change-id: 20220921-single-patch-14c602afcb99

Best regards,
-- 
Konstantin Ryabitsev <konstantin@linuxfoundation.org>
