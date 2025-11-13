From: David Heidelberg <david@ixit.cz>
Date: Thu, 13 Nov 2025 18:57:42 +0100
Subject: [PATCH v2 08/12] drm/panel: sofef00: Initialise at 50% brightness
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251113-sofef00-rebuild-v2-8-e175053061ec@ixit.cz>
References: <20251113-sofef00-rebuild-v2-0-e175053061ec@ixit.cz>
In-Reply-To: <20251113-sofef00-rebuild-v2-0-e175053061ec@ixit.cz>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jessica.zhang@oss.qualcomm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=858; i=david@ixit.cz;
 h=from:subject:message-id; bh=vjrHJH4EY6FJhDpprnzSkcksIGyeb+RoENa3mCki5mI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpFhwVq+Kvp/Q4ZFwd7BdYq9nz4hZ0VZGi+hHN7
 6pvliM5AyuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRYcFQAKCRBgAj/E00kg
 cgr+D/0TxPbmtYkFeycn3efdBGre+Z0Wbh3+TXY0BxAqq5KwwK3M1JjLIlHoi2ttO1ravPKzlbt
 y/BUiEFPIHIbZlAAkbdgVbanwRgSxaO/eLh2UmPnL/g2JRKEEUVit1IPvd6iw7NfN1w+9IuDqzc
 LD1C27DWYH9bB5bs9pKQKJWkuCOHuUXv6dZkBrL1qG76ApUxOUaveHoyvCz2jzWWAzDvLL6ejfu
 YcZWQpuHnWZP+gEge+VXy7mpdiZjKq0t7JhQwtdk6eaTJcQLfpCrL6RMdwO5tPembd6zxNwlktl
 7fpccxsE3ws6HeUw85SyDOGd9W2Mvjk3/HqRvuukFXGydsgQJApsw8dEtfvY9PZQg1r1EkmmvxT
 jHeOJ4skoweazWxvLyF4WGAjELkmcRZFLNcdT+Ra7x+NWID8rOEI+UWcJdB/wXxVMsURKQON8vf
 0vF3hVdCdYl48HYWs1G6ODFBi7DvnOAYL6L8OPqmBFfhMifff7aX95DXGtaDGvw7i8EUNpsbp8A
 CLRkmsXDaYOgrneEdEEHt9pgS/Ei8oNBbJAbfXXMuwMOjF0sVXyQsjfFVfy2zTVX/rnd52C00WG
 +CKQpWiyoqdcKX9pgh2Xxs46LMsh0+lIJqbGqC53xXXSms8NDTWyHzE2VYG20MiTsRViHzEZKR/
 pnSKjk8LQWdJWxQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

Initialising at max brightness is not necessary.
Half brightness is much more comfortable.

Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-samsung-sofef00.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/panel/panel-samsung-sofef00.c b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
index 0d3ae0689a19b..d1e5340d7e337 100644
--- a/drivers/gpu/drm/panel/panel-samsung-sofef00.c
+++ b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
@@ -204,7 +204,7 @@ sofef00_create_backlight(struct mipi_dsi_device *dsi)
 	struct device *dev = &dsi->dev;
 	const struct backlight_properties props = {
 		.type = BACKLIGHT_PLATFORM,
-		.brightness = 1023,
+		.brightness = 512,
 		.max_brightness = 1023,
 	};
 

-- 
2.51.0

