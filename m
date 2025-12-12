From: Chen Linxuan <me@black-desk.cn>
Date: Sat, 13 Dec 2025 02:03:56 +0800
Subject: [PATCH] vfs: fix EBUSY on FSCONFIG_CMD_CREATE retry
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251213-mount-ebusy-v1-1-7b2907b7b0b2@black-desk.cn>
X-B4-Tracking: v=1; b=H4sIAAtZPGkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDI0Nj3dz80rwS3dSk0uJKXYvUVGMLC4tE81STNCWgjoKi1LTMCrBp0bG
 1tQAh9eyyXQAAAA==
X-Change-ID: 20251213-mount-ebusy-8ee3888a7e4f
To: Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Chen Linxuan <me@black-desk.cn>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2189; i=me@black-desk.cn;
 h=from:subject:message-id; bh=XvsMIeYd2rV7bHfMQnljLFRBG0G+Pqcltlcqwj85FJ4=;
 b=owEBbQKS/ZANAwAIAXYe5hQ5ma6LAcsmYgBpPFkMp2MbCTnXsEEnX/RgESPjyj5BJqKwiBcrh
 MU63YkVTe2JAjMEAAEIAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCaTxZDAAKCRB2HuYUOZmu
 i9dND/9g2Ml4ZJnUasI12G14g/xCT+CsCPBsb41Gd37CNx6s0DJHG/zieGFlT6ARgiPfNnW7jWM
 7qWqPKN5nbnVXg3qMrSCGNMSQqfCyLSwwR4c+b8dUUPfGgQJOR8NeOCWYcf3FmYrHzLtXGwktxY
 meX0K0drxQr77n9SvPb4gAqifLaF4YdB9qTwptLgEwJCbZEZdG5srLP5IbQl8+pwvGsYRKLxPhE
 Bprp6RJTgMsTkbatXJ/KUtXmjLJAmzydGm00AkGJqC0XJHDiSfx6QLnQN37Lk5Q1Fwne1XScvhc
 ljlsdqGpgl/8JgC+rT+W+Q9Ko13UPt/yAKQFzNaSBm7Yly1Y6QC3giwdEf7D38wMPa7Gvo7QpzD
 wNf0zGqTsbbq1nsOYb73PAZAAFlcgKaK4fD/yK7t+xSxWM05jsAIQ7VVaJl1gGjp4EbQ2qM8NEZ
 56lE1y0ujWOWgIVnsIcYa8+n0+s4kcflTexqpUZA/92AlkJl3uH51we3o+jmqDytTF+dJf142bQ
 AzXWQNf9kK2jHD/vW1HbKo4IBwG5twZIQSr+Xdsp2JI9ki9oRj1gJKN26E10anwewDVGnGkIbER
 6EwQmfenTSixvCaMVc/IYYGJTVX1pTHOodcR44JNO72pgxnpPdLiZ8tHkCJ+97Q2XG8NBlSDaI+
 Rxvp5oSR0i41mWw==
X-Developer-Key: i=me@black-desk.cn; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for me@black-desk.cn/default with auth_id=573
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When using fsconfig(..., FSCONFIG_CMD_CREATE, ...), the filesystem
context is retrieved from the file descriptor. Since the file structure
persists across syscall restarts, the context state is preserved:

	// fs/fsopen.c
	SYSCALL_DEFINE5(fsconfig, ...)
	{
		...
		fc = fd_file(f)->private_data;
		...
		ret = vfs_fsconfig_locked(fc, cmd, &param);
		...
	}

In vfs_cmd_create(), the context phase is transitioned to
FS_CONTEXT_CREATING before calling vfs_get_tree():

	// fs/fsopen.c
	static int vfs_cmd_create(struct fs_context *fc, bool exclusive)
	{
		...
		fc->phase = FS_CONTEXT_CREATING;
		...
		ret = vfs_get_tree(fc);
		...
	}

However, vfs_get_tree() may return -ERESTARTNOINTR if the filesystem
implementation needs to restart the syscall. For example, cgroup v1 does
this when it encounters a race condition where the root is dying:

	// kernel/cgroup/cgroup-v1.c
	int cgroup1_get_tree(struct fs_context *fc)
	{
		...
		if (unlikely(ret > 0)) {
			msleep(10);
			return restart_syscall();
		}
		return ret;
	}

If the syscall is restarted, fsconfig() is called again and retrieves
the *same* fs_context. However, vfs_cmd_create() rejects the call
because the phase was left as FS_CONTEXT_CREATING during the first
attempt:

	if (fc->phase != FS_CONTEXT_CREATE_PARAMS)
		return -EBUSY;

Fix this by resetting fc->phase back to FS_CONTEXT_CREATE_PARAMS if
vfs_get_tree() returns -ERESTARTNOINTR.

Cc: stable@vger.kernel.org
Signed-off-by: Chen Linxuan <me@black-desk.cn>
---
 fs/fsopen.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/fs/fsopen.c b/fs/fsopen.c
index f645c99204eb..8a7cb031af50 100644
--- a/fs/fsopen.c
+++ b/fs/fsopen.c
@@ -229,6 +229,10 @@ static int vfs_cmd_create(struct fs_context *fc, bool exclusive)
 	fc->exclusive = exclusive;
 
 	ret = vfs_get_tree(fc);
+	if (ret == -ERESTARTNOINTR) {
+		fc->phase = FS_CONTEXT_CREATE_PARAMS;
+		return ret;
+	}
 	if (ret) {
 		fc->phase = FS_CONTEXT_FAILED;
 		return ret;

---
base-commit: 187d0801404f415f22c0b31531982c7ea97fa341
change-id: 20251213-mount-ebusy-8ee3888a7e4f

Best regards,
-- 
Chen Linxuan <me@black-desk.cn>

