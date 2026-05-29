From: Dominique Martinet <asmadeus@codewreck.org>
Date: Fri, 29 May 2026 12:09:20 +0900
Subject: [PATCH] 9p: v9fs_file_do_lock: replace WARN_ONCE with p9_debug
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260529-lock-warn-v1-1-20c29580d61d@codewreck.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDUyNL3Zz85Gzd8sSiPN00A0OT5MRky6TElBQloPqCotS0zAqwWdGxtbU
 AeC/07VsAAAA=
X-Change-ID: 20260529-lock-warn-f014cac9badd
To: Eric Van Hensbergen <ericvh@kernel.org>, 
 Latchesar Ionkov <lucho@ionkov.net>, 
 Christian Schoenebeck <linux_oss@crudebyte.com>
Cc: v9fs@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Yifei Chu <yifeichu24@gmail.com>, 
 Dominique Martinet <asmadeus@codewreck.org>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=openpgp-sha256; l=1073;
 i=asmadeus@codewreck.org; h=from:subject:message-id;
 bh=4/mZa49DWHG6WAg/Twqmw7YhHfcEeqma4x3bjMrCRog=;
 b=owEBbQKS/ZANAwAKAatOm+xqmOZwAcsmYgBqGQNugTQrakmwajTIPUO5RKczOvfdgPSn6C00k
 Hi4PuivyqyJAjMEAAEKAB0WIQT8g9txgG5a3TOhiE6rTpvsapjmcAUCahkDbgAKCRCrTpvsapjm
 cAVZEACnitp9Z31dzO9xeHzYzeLbOaIb9qbb1/Sz1wz8cosuoMNifBnBHQH+TUGOcnKwMMNLSf4
 mDqJMJEEn1B7rJl/os7fEAtrz8MqZAB34/U0wABJPpq/PP3OoMe3ulyk/cjEdCfsFlwtypuhuGU
 WZCsQJPOLT9ZDArdoDV0IZR+fY14rbeuWt2fGEQPTfDrbhCvzw06QZlw3SNxG8uFHTqySFot/eI
 L5JX+ITeKEUrv9VpuNkDesrskFKd6F12N/uZHRTwmplH7IpoHwi3i86ZwLBYdAm99L8zm6CUu2A
 w5diBxwVVDJ0mZptR+mOlc5okQUEN7aaWQU/QewbKtH80TMvaiV1ds+EyLD7mjg8o3qB9F+vLK/
 E4qEWEf1Yx+XXlv1/jyX2OwMadtj5YHwy+RSsqhg+tvugekYGKcjDye7WaEiJptwdKxC5WCIaEX
 /69x7Apj6SccANfBj/ye11Px3pFvArBWYgssWlaaat+gIYwylCzQ7rXoqU9zZy7kK7amCT2evLS
 SWsIS/R2SP0TqIouz732rb9ClpupKbzTR8OIyHXXXmzemIlRwWZ8wwAozSrtzZkdzS1a1mPhmjc
 WYNQBytmfNuBrD4MuBFGSbxfBGTZzgD0e7ZzC73jrlxCOcvVePFyG2t8GUD1BGQjTojqXD1pY0k
 8LEkE+dXuux/cUQ==
X-Developer-Key: i=asmadeus@codewreck.org; a=openpgp;
 fpr=B894379F662089525B3FB1B9333F1F391BBBB00A
X-Endpoint-Received: by B4 Relay for asmadeus@codewreck.org/default with auth_id=435
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This warning depends on server-provided data, we should not use
WARN here

Reported-by: Yifei Chu <yifeichu24@gmail.com>
Closes: https://lore.kernel.org/r/CAPJnbgJ7ZK7DCjCfG56hd_iKGePmAzudb4hOWd4=9r32nM+KcA@mail.gmail.com
Signed-off-by: Dominique Martinet <asmadeus@codewreck.org>
---
 fs/9p/vfs_file.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/fs/9p/vfs_file.c b/fs/9p/vfs_file.c
index c5e73c37baea55394294b939fdda7170db8503c0..cddfb4b7ce4e22aacad7b51f6e6cbd164b7c2f8f 100644
--- a/fs/9p/vfs_file.c
+++ b/fs/9p/vfs_file.c
@@ -198,7 +198,7 @@ static int v9fs_file_do_lock(struct file *filp, int cmd, struct file_lock *fl)
 		res = -EAGAIN;
 		break;
 	default:
-		WARN_ONCE(1, "unknown lock status code: %d\n", status);
+		p9_debug(P9_DEBUG_ERROR, "unknown lock status code: %d\n", status);
 		fallthrough;
 	case P9_LOCK_ERROR:
 	case P9_LOCK_GRACE:

---
base-commit: 3ec9e935015b11236ba778885d89e399f00d6b50
change-id: 20260529-lock-warn-f014cac9badd

Best regards,
-- 
Dominique Martinet <asmadeus@codewreck.org>

