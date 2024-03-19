From: Foo Barski <mricon@gmail.com>
Date: Tue, 19 Mar 2024 10:20:17 -0400
Subject: [PATCH v4] Change release name for testing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240319-this-is-a-super-long-branch-name-that-will-most-certainly-trigger-badness-from-web-endpoint-v4-1-e95692e9106d@gmail.com>
X-B4-Tracking: v=1; b=H4sIACCf+WUC/73QwW7DIAwG4FepOM9VSOjS7tT3mHYwYIilBCIga
 asq7z7aXfYEkXz5LVv+5KfIlJiy+Do8RaKVM8dQg/o4CDNg8ARsaxZt06qmkxcoA2eohZCXmRK
 MMXjQCYMZIOBEdQAL3HgcYYq5gKFUkMP4gJLY+7qh0QbKGVyKE9xIAwU7Rw4FenU6o2rRWfspq
 mBO5Pj+1n3/1FxPl5geb+wqX919XKsECbZHd7ENWkl0HTksdxeXYLHUjx1j8uIlXNsdVW1Vua4
 O9MYpOqmrn5DHo4nTn6Xb0dJVC2mtrZRnZZz8b9m27Rdw4+ixaAIAAA==
To: test@lists.linux.dev
Cc: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
X-Mailer: b4 0.14-dev
X-Developer-Signature: v=1; a=openpgp-sha256; l=1332; i=mricon@gmail.com;
 h=from:subject:message-id; bh=16N6DQG6vj0LeiDcAXvzc3zE9QtegchSglfXozus0I0=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGFJ/zlf6OyPylVl/sZlLX6E8W5CKGFtsy1ppw3kaGnutn
 Hw/rJnVUcrCIMbFICumyFK2L3ZTUOFDD7n0HlOYOaxMIEMYuDgFYCIKExkZVmT29tiHBbPWTvxl
 k2hz54o/i/TNlfc5o3x0QhYzs1zVYfjvu8PtZ0d2tP/+EBchtp6sZbPvxN0MWsJ47qhnq8IK/iJ
 2AA==
X-Developer-Key: i=mricon@gmail.com; a=openpgp;
 fpr=DE0E66E32F1FDD0902666B96E63EDCA9329DD07E
X-Endpoint-Received: by B4 Relay for mricon@gmail.com/default with auth_id=141
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I just need a commit to test things.

Signed-off-by: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
---
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

