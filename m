From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 01 Mar 2023 18:56:19 +0000
Subject: [PATCH RESEND v2 05/16] WHENCE: comment out duplicate MediaTek
 firmware
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230301-fixes-and-compression-v2-5-e2b71974e842@gmail.com>
References: <20230301-fixes-and-compression-v2-0-e2b71974e842@gmail.com>
In-Reply-To: <20230301-fixes-and-compression-v2-0-e2b71974e842@gmail.com>
To: linux-firmware@kernel.org
Cc: Josh Boyer <jwboyer@kernel.org>, Adam Sampson <ats@offog.org>, 
 David Woodhouse <dwmw2@infradead.org>, 
 Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1677696976; l=777;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=y/dsWtna2WkULqajga1juBXTFdyO0iJ6fIGKMsgSkJs=;
 b=8mPWGuKxknU01+gpIjc4cBlDjm1aNQpar8GYb4EjQ2C4BtgCUtAzO47EieISM0hjkqE3MEN7S
 rPMtmWX/MJZB0lnyMMLowkL82xHhgOVh9gUikHsLzG24nFe3HBJEdBy
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As mentioned in the inline comment - file is already listed further
down. To prevent check_whence.py errors, comment it out.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 WHENCE | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/WHENCE b/WHENCE
index 7de6d6b..bce94c5 100644
--- a/WHENCE
+++ b/WHENCE
@@ -5183,8 +5183,9 @@ File: mediatek/mt7622pr2h.bin
 Version: 20180621204904
 File: mediatek/mt7668pr2h.bin
 Version: 20180517181834
-File: mediatek/mt7663pr2h.bin
-Version: 7663e2ccn04-2006030247
+# Note: explicitly commented out, since it's duplicated further down
+# File: mediatek/mt7663pr2h.bin
+# Version: 7663e2ccn04-2006030247
 
 Licence: Redistributable. See LICENCE.mediatek for details.
 

-- 
2.39.2

