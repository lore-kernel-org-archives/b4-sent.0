From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sun, 14 Jun 2026 00:36:12 -0500
Subject: [PATCH 2/2] Input: synaptics-rmi4 - bound the F30 keymap to the
 GPIO/LED count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260614-b4-disp-818d6bda-v1-2-cf39a3615085@proton.me>
References: <20260614-b4-disp-818d6bda-v1-0-cf39a3615085@proton.me>
In-Reply-To: <20260614-b4-disp-818d6bda-v1-0-cf39a3615085@proton.me>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-kernel@vger.kernel.org, Hans de Goede <hansg@kernel.org>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>, linux-input@vger.kernel.org, 
 Andrew Duggan <aduggan@synaptics.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781415370; l=1673;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=qeGYmDQV4/varPHdBXmYNMaMCeZqzNjTiG7YT4l+RVU=;
 b=nMwMJdDCpdLABBi8XPZy7jhOOjVibgWW+ZbHJIb4P+d5n2bTFYGaDi1DqbJk2ZXPEONnCe/rK
 oljTyEbu4m9ClWO3Y13eN5V1Hp7QViLj/3px8RqBkfjW/pKVecBKeKh
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rmi_f30_map_gpios() allocates gpioled_key_map with
min(gpioled_count, TRACKSTICK_RANGE_END) == at most 6 entries, but
rmi_f30_attention() iterates the full f30->gpioled_count (device query
register, range 0..31) and dereferences gpioled_key_map[i], and
input->keycodemax is set to the full gpioled_count while input->keycode
points at the 6-entry allocation.

A device that reports gpioled_count > 6 with GPIO support enabled
therefore causes an out-of-bounds read on the attention interrupt and
out-of-bounds read/write through the EVIOCGKEYCODE/EVIOCSKEYCODE ioctls,
which bound the index only against keycodemax. This is the same defect
as the F3A handler, which was copied from F30.

Size the keymap for the full gpioled_count; the mapping loop still
assigns only the first min(gpioled_count, TRACKSTICK_RANGE_END) entries.

Fixes: 3e64fcbdbd10 ("Input: synaptics-rmi4 - limit the range of what GPIOs are buttons")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/input/rmi4/rmi_f30.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/input/rmi4/rmi_f30.c b/drivers/input/rmi4/rmi_f30.c
index 35045f161dc2..b2155c8e20e7 100644
--- a/drivers/input/rmi4/rmi_f30.c
+++ b/drivers/input/rmi4/rmi_f30.c
@@ -233,7 +233,7 @@ static int rmi_f30_map_gpios(struct rmi_function *fn,
 	int button_count = min_t(u8, f30->gpioled_count, TRACKSTICK_RANGE_END);
 
 	f30->gpioled_key_map = devm_kcalloc(&fn->dev,
-					    button_count,
+					    f30->gpioled_count,
 					    sizeof(f30->gpioled_key_map[0]),
 					    GFP_KERNEL);
 	if (!f30->gpioled_key_map) {

-- 
2.43.0

