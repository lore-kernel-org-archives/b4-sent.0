From: Cunhao Lu <1579567540@qq.com>
Date: Fri, 23 Oct 2026 16:21:05 +0800
Subject: [PATCH] gpio: rockchip: Fix debounce arithmetic for GPIO v2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-fix-rockchip-gpio-v2-debounce-v1-1-f1141bd5b58f@qq.com>
X-B4-Tracking: v=1; b=H4sIAPAY22oC/yXMQQrCMBBG4auUWTuQTqFFryIu7OS3HYUkJLYUS
 u9u1OW3eG+ngmwodGl2ylitWAwV7akhne9hApuvJnHSt046ftjGOepLZ0s8JYu8CnuMcQkKPru
 hH9RD4Duqj5RRg9//evu7LOMT+v5O6Tg+e9INuoEAAAA=
X-Change-ID: 20261023-fix-rockchip-gpio-v2-debounce-90767cde2ed3
To: Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Jianqun Xu <jay.xu@rock-chips.com>
Cc: linux-gpio@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Cunhao Lu <1579567540@qq.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792743678; l=3798;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=990tz6V6xSqlnsWsntOcrs9gs3SDwAyWpRr2l3eS5jA=;
 b=MT2tjLEkyabOrZ4KFYK1MjnqubLChv5mTzLHiyvAzJ27voIKRUdgCfGc/HuEDJpf4r0Ur6HxK
 vjeJI+cZ4ILCoeBSjnIhtn2ioR6lVFz7/f31Em4yLqEq8ZqZtgJwf7S
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The debounce interval calculations use unsigned long operands. On 32-bit
systems, the numerator used to calculate the maximum interval overflows
before division, while multiplying the requested interval by the clock
rate overflows before it is assigned to a u64. A zero debounce clock rate
also causes division by zero.

Use 64-bit arithmetic for both calculations and reject a zero clock rate
before division.

At 32768 Hz, a 1 us request rounds to zero divider periods. Subtracting
one then wraps the divider value to ULONG_MAX. Decrement only a nonzero
rounded period count so that such requests use the smallest divider
value.

Fixes: 3bcbd1a85b68 ("gpio/rockchip: support next version gpio controller")
Cc: stable@vger.kernel.org
Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
This pre-existing issue was found by Sashiko AI during the RK3572
mainlining work:
https://sashiko.dev/#/patchset/20261022-add-board-ok3572-c-v1-0-0b0fd85a31ee@qq.com?part=9

On 32-bit systems, the unsigned long products used to calculate the
maximum and requested debounce intervals can overflow before being
assigned to u64. A zero debounce clock rate also causes division by
zero. In addition, at 32768 Hz, a 1 us request rounds to zero divider
periods, so subtracting one underflows to ULONG_MAX.

This patch performs both interval calculations in 64-bit arithmetic,
rejects a zero clock rate, and avoids decrementing a zero rounded period
count. The existing set_config fallback and divider register accesses
are unchanged.

Validation:

- A host reproducer confirmed the 32768 Hz, 1 us underflow and the
  incorrect maximum interval produced by 32-bit arithmetic.
- The combined GPIO arithmetic suite passed 126 cases for each modeled
  arithmetic width, covering both legacy GPIO v2 and RK3572 V2.7. The
  suite includes zero-clock-rate and request-boundary cases. The 32-bit
  run models unsigned long arithmetic; the 64-bit run uses the native
  host width. Both are arithmetic-level host tests, not ARM32 hardware
  or electrical tests.

AI assistance:

- Codex / DeepSeek V4.1 Flash were used for:
  - Collecting data
  - Automating tests
  - Reviewing and adjusting code style to follow community conventions
---
 drivers/gpio/gpio-rockchip.c | 15 ++++++++++-----
 1 file changed, 10 insertions(+), 5 deletions(-)

diff --git a/drivers/gpio/gpio-rockchip.c b/drivers/gpio/gpio-rockchip.c
index 77b239a9a601..714604c11d78 100644
--- a/drivers/gpio/gpio-rockchip.c
+++ b/drivers/gpio/gpio-rockchip.c
@@ -201,20 +201,25 @@ static int rockchip_gpio_set_debounce(struct gpio_chip *gc,
 {
 	struct rockchip_pin_bank *bank = gpiochip_get_data(gc);
 	const struct rockchip_gpio_regs	*reg = bank->gpio_regs;
-	unsigned long flags, div_reg, freq, max_debounce;
+	unsigned long flags, div_reg, freq;
 	bool div_debounce_support;
 	unsigned int cur_div_reg;
-	u64 div;
+	u64 div, max_debounce;
 
 	if (bank->gpio_type == GPIO_TYPE_V2 && !IS_ERR(bank->db_clk)) {
 		div_debounce_support = true;
 		freq = clk_get_rate(bank->db_clk);
-		max_debounce = (GENMASK(23, 0) + 1) * 2 * 1000000 / freq;
+		if (!freq)
+			return -EINVAL;
+
+		div = (u64)(GENMASK(23, 0) + 1) * 2 * USEC_PER_SEC;
+		max_debounce = div64_u64(div, freq);
 		if (debounce > max_debounce)
 			return -EINVAL;
 
-		div = debounce * freq;
-		div_reg = DIV_ROUND_CLOSEST_ULL(div, 2 * USEC_PER_SEC) - 1;
+		div = (u64)debounce * freq;
+		div_reg = DIV_ROUND_CLOSEST_ULL(div, 2 * USEC_PER_SEC);
+		div_reg = div_reg ? div_reg - 1 : 0;
 	} else {
 		div_debounce_support = false;
 	}

---
base-commit: 734bef548a96e8774d6eef5dfa2026c6edc4e80b
change-id: 20261023-fix-rockchip-gpio-v2-debounce-90767cde2ed3

Best regards,
--  
Cunhao Lu <1579567540@qq.com>

