From: Ludvig Michaelsson <ludvig.michaelsson@yubico.com>
Date: Wed, 21 Jun 2023 13:17:43 +0200
Subject: [PATCH] HID: hidraw: fix data race on device refcount
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230621-hidraw-race-v1-1-a58e6ac69bab@yubico.com>
X-B4-Tracking: v=1; b=H4sIAFbckmQC/x2NQQqEMAxFryJZT8FUxoVXGVykbbRZ2JFEHEG8u
 3WW730e/wRjFTYYmhOUdzH5lgr4aiBmKjM7SZXBt75re48uS1L6OaXILrwxIIYJkRPUIpBVqVR
 ifpqFbGN9hlV5kuN/8xmv6waz9WPwdgAAAA==
To: Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <benjamin.tissoires@redhat.com>, 
 =?utf-8?q?Andr=C3=A9_Almeida?= <andrealmeid@igalia.com>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ludvig Michaelsson <ludvig.michaelsson@yubico.com>
X-Mailer: b4 0.12.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1903;
 i=ludvig.michaelsson@yubico.com; h=from:subject:message-id;
 bh=H+F1GtqsL31H9za8Cp+DCcNUqK2U4w+0+a9OPk49764=;
 b=owJ4nJvAy8zAJWab5fnkyINtxYyn1ZIYUibdmRlX2tG4s3tDGdfyaQ+1fizccmSzmKnMjKvTT
 51TYl94IECno5SFQYyLQVZMkWVzAfN/0QUZS4SfcsvAzGFlAhnCwMUpABMpEmT4pyN1vSThYWFb
 Oss69VsFraGikyKTnh3ao7tnT6jToYPV3Qz/q2W85zi8F1t3TW73EdkjXJ0+M9enGVU5GYSZVlj
 G8IjwAgB2p0pI
X-Developer-Key: i=ludvig.michaelsson@yubico.com; a=openpgp;
 fpr=78D997D53E9C0A2A205392ED14A19784723C9988
X-Endpoint-Received: by B4 Relay for ludvig.michaelsson@yubico.com/default with auth_id=54
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The hidraw_open() function increments the hidraw device reference
counter. The counter has no dedicated synchronization mechanism,
resulting in a potential data race when concurrently opening a device.

The race is a regression introduced by commit 8590222e4b02 ("HID:
hidraw: Replace hidraw device table mutex with a rwsem"). While
minors_rwsem is intended to protect the hidraw_table itself, by instead
acquiring the lock for writing, the reference counter is also protected.
This is symmetrical to hidraw_release().

Link: https://github.com/systemd/systemd/issues/27947
Fixes: 8590222e4b02 ("HID: hidraw: Replace hidraw device table mutex with a rwsem")
Signed-off-by: Ludvig Michaelsson <ludvig.michaelsson@yubico.com>
---
 drivers/hid/hidraw.c | 9 +++++++--
 1 file changed, 7 insertions(+), 2 deletions(-)

diff --git a/drivers/hid/hidraw.c b/drivers/hid/hidraw.c
index 93e62b161501..e63c56a0d57f 100644
--- a/drivers/hid/hidraw.c
+++ b/drivers/hid/hidraw.c
@@ -272,7 +272,12 @@ static int hidraw_open(struct inode *inode, struct file *file)
 		goto out;
 	}
 
-	down_read(&minors_rwsem);
+	/*
+	 * Technically not writing to the hidraw_table but a write lock is
+	 * required to protect the device refcount. This is symmetrical to
+	 * hidraw_release().
+	 */
+	down_write(&minors_rwsem);
 	if (!hidraw_table[minor] || !hidraw_table[minor]->exist) {
 		err = -ENODEV;
 		goto out_unlock;
@@ -301,7 +306,7 @@ static int hidraw_open(struct inode *inode, struct file *file)
 	spin_unlock_irqrestore(&hidraw_table[minor]->list_lock, flags);
 	file->private_data = list;
 out_unlock:
-	up_read(&minors_rwsem);
+	up_write(&minors_rwsem);
 out:
 	if (err < 0)
 		kfree(list);

---
base-commit: 45a3e24f65e90a047bef86f927ebdc4c710edaa1
change-id: 20230621-hidraw-race-b51b11bf11ed

Best regards,
-- 
Ludvig Michaelsson <ludvig.michaelsson@yubico.com>

