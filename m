From: Shuming Fan <shumingf@realtek.com>
Date: Thu, 24 Sep 2026 13:53:02 +0800
Subject: [PATCH v2 1/3] soundwire: intel_auxdevice: add rt766/rt767 codec
 to wake_capable_list
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-rt766-v2-1-e0b63606a5e8@realtek.com>
References: <20260924-rt766-v2-0-e0b63606a5e8@realtek.com>
In-Reply-To: <20260924-rt766-v2-0-e0b63606a5e8@realtek.com>
To: broonie@kernel.org, lgirdwood@gmail.com
Cc: Shuming Fan <shumingf@realtek.com>, derek.fang@realtek.com, 
 lars@metafoo.de, oder_chiou@realtek.com, linux-sound@vger.kernel.org, 
 flove@realtek.com, jack.yu@realtek.com
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790229204; l=641;
 i=shumingf@realtek.com; s=20260924; h=from:subject:message-id;
 bh=BcqE/gWuYULZgVfRl/cyCWha2hHxTRJOfhcwZccN2sI=;
 b=JK46BUbnobj1xIlSUl61xxNE9riixDgZJ5dOiPv8Vnzk0GsiFRgEzUD+E7Tuof4UTD2Dy7Mhq
 Q2OY67cIy4KBLuPaVfikjd9z9WXGJ2WjqtxZx0qUODY/XGN+2aW1R6r
X-Developer-Key: i=shumingf@realtek.com; a=ed25519;
 pk=ZM8Pg7tEJ0SDXQeBw6SfvcYyqXU9nF88DuTyxzf9utE=
X-Endpoint-Received: by B4 Relay for shumingf@realtek.com/20260924 with auth_id=1053
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rt766/rt767 have wake capability. Add it to the wake_capable_list.

Signed-off-by: Shuming Fan <shumingf@realtek.com>
---
 drivers/soundwire/intel_auxdevice.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/soundwire/intel_auxdevice.c b/drivers/soundwire/intel_auxdevice.c
index a8407560bf4f..bcf94ea38cab 100644
--- a/drivers/soundwire/intel_auxdevice.c
+++ b/drivers/soundwire/intel_auxdevice.c
@@ -73,6 +73,8 @@ static struct wake_capable_part wake_capable_list[] = {
 	{0x025d, 0x717},
 	{0x025d, 0x721},
 	{0x025d, 0x722},
+	{0x025d, 0x766},
+	{0x025d, 0x767},
 	{0x04b3, 0x9356},
 };
 

-- 
2.55.0

