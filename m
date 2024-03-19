From: Foo Barski <mricon@gmail.com>
Date: Tue, 19 Mar 2024 11:58:13 -0400
Subject: [PATCH v7] Change release name for testing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240319-this-is-a-super-long-branch-name-that-will-most-certainly-trigger-badness-from-web-endpoint-v7-1-893f19fb97fc@gmail.com>
X-B4-Tracking: v=1; b=H4sIABS2+WUC/73QwW7CMAwG4FeZcp5Rk6Yt2Yn3mHZwGqdEahOUh
 AJCvPsMu0w8QCVffsuWP/kuCuVARXx93EWmNZSQIofh80OMR4wTQXCchWqUblppoB5DAS6Ecj5
 RhjnFCWzGOB4h4kI8gBUuYZ5hSaXCSLliiPMNag7TxBsWXaRSwOe0wIUsUHSnFGKFQXd71Aq9c
 71gwSmTD9eX7vuHM5+uKd9e2FU+u9u4VgkS3IDeuAadJDrMIZ6vPp2jw8of26U8iadwVRuqFKt
 8ywPD6DV1+jAtGObdmJY/S7uhpWULWWudlHs9evlu0Rta9NNiut4oMrLp3bul29DSsaXv1N4qG
 jrVDu+WfkNLzxZDqnGtb8gg/bc8Ho9fip5CRQwEAAA=
To: test@lists.linux.dev
Cc: =?utf-8?q?Fak=C3=A9_Nam=C3=A9?= <mricon@kernel.org>, 
 Konstantin Ryabitsev <konstantin@linuxfoundation.org>
X-Mailer: b4 0.14-dev
X-Developer-Signature: v=1; a=openpgp-sha256; l=1896; i=mricon@gmail.com;
 h=from:subject:message-id; bh=6F7lmmrMiud0ZDiG14ef6txBfil8FENJ/U+MEZ0MaE8=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGFJ/bhOT7XoR/vhTO0tRTVCM4+qOb1czGmd0Ri05E39DS
 /OtZCVbRykLgxgXg6yYIkvZvthNQYUPPeTSe0xh5rAygQxh4OIUgIkwxzP8j/rgF1+um7mi86zQ
 /cpHfw0ljSfeU9XZJrnSIOm37qQXAQz/jOXXPbZse7B449dp56MEOiV5S1ZP7ZM4cy20+cfXQzX
 CbAA=
X-Developer-Key: i=mricon@gmail.com; a=openpgp;
 fpr=DE0E66E32F1FDD0902666B96E63EDCA9329DD07E
X-Endpoint-Received: by B4 Relay for mricon@gmail.com/default with auth_id=141
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I just need a commit to test things.

Signed-off-by: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
---
Changes in v7:
- Link to v6: https://lore.kernel.org/r/20240319-this-is-a-super-long-branch-name-that-will-most-certainly-trigger-badness-from-web-endpoint-v6-1-9e20d3f0e9ae@gmail.com

Changes in v6:
- Link to v5: https://lore.kernel.org/r/20240319-this-is-a-super-long-branch-name-that-will-most-certainly-trigger-badness-from-web-endpoint-v5-1-6528b2e75237@gmail.com

Changes in v5:
- Link to v4: https://lore.kernel.org/r/20240319-this-is-a-super-long-branch-name-that-will-most-certainly-trigger-badness-from-web-endpoint-v4-1-e95692e9106d@gmail.com

Changes in v4:
- Link to v3: https://lore.kernel.org/r/20240319-this-is-a-super-long-branch-name-that-will-most-certainly-trigger-badness-from-web-endpoint-v3-1-ebbbd1184cf1@gmail.com

Changes in v3:
- Link to v2: https://lore.kernel.org/r/20240319-this-is-a-super-long-branch-name-that-will-most-certainly-trigger-badness-from-web-endpoint-v2-1-f3bad7cf4e54@gmail.com

Changes in v2:
- Link to v1: https://lore.kernel.org/r/20240319-this-is-a-super-long-branch-name-that-will-most-certainly-trigger-badness-from-web-endpoint-v1-1-d7af9d0ad1ee@linuxfoundation.org
---
 Makefile | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Makefile b/Makefile
index 6fe2ae1a6d92..a9337857096a 100644
--- a/Makefile
+++ b/Makefile
@@ -3,7 +3,7 @@ VERSION = 6
 PATCHLEVEL = 8
 SUBLEVEL = 0
 EXTRAVERSION =
-NAME = Hurr durr I'ma ninja sloth
+NAME = Testing Web Endpoint
 
 # *DOCUMENTATION*
 # To see a list of typical targets execute "make help"

---
base-commit: b3603fcb79b1036acae10602bffc4855a4b9af80
change-id: 20240319-this-is-a-super-long-branch-name-that-will-most-certainly-trigger-badness-from-web-endpoint-7458a42afdd6

Best regards,
-- 
Foo Barski <mricon@gmail.com>

