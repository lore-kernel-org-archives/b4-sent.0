From: David Heidelberg <david@ixit.cz>
Date: Tue, 04 Nov 2025 23:16:16 +0100
Subject: [PATCH 08/12] drm/panel: sofef00: Initialise at 50% brightness
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251104-sofef00-rebuild-v1-8-dfcfa17eb176@ixit.cz>
References: <20251104-sofef00-rebuild-v1-0-dfcfa17eb176@ixit.cz>
In-Reply-To: <20251104-sofef00-rebuild-v1-0-dfcfa17eb176@ixit.cz>
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
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpCnss7ioIaB4Vn83ddXF7/bWJwnVZnrJ7v1T7z
 rUkYUUTU2uJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaQp7LAAKCRBgAj/E00kg
 cqbcEAC7O0ACBx2lh2Z/DMIYqPFPfs7X6TdoUa0MoUDHyWseBCo5JDa0JYVyUq51CJldk5EljHW
 dB1FrnKzy1E80sbj8eRvDPh5Ei+8KfJW/fGdNWNZRqG/765s+oO5R0o5d5tpv4KnuDYwaoi+TkT
 9pMWFAHOO/9mKnt5TTfjFu1On4guFnprjl3LmwIavRekvC3hg7ymj1Zl+bJXQIIYy/imvb6WPbS
 o/YcjzCBedfldstrg1EzP7ChVY9ygQf0fIh3fUX14pO/JBctpH/RWjlENskK29aNDQOLkC9pqPl
 2Ybzt7GFnyEHsccVTVCtNpUh1Mlng5eNNrz2YElGPFdI4HyZ/cIDFh6waXAtV3lPw/heyj6rM5P
 SledLJjM6B172MzWItLynytxNNXrUamWMwyyBv6pvQ6w57XaRrjEMZaLEYst9kiayA0wdcOsbDN
 A03l33lo+MrEOV2/BGe57U1SwH4eORWF+W5lwyY7KI0ZJwUNUwJCqU4xd/I4Ca6pzolIP2uSFA5
 0bCVapWEajMQTxeDloNE/r18+KkjNrtFuh2vfWdWOgcJuQ+5XLnk3a8rESppmWao8x6cSyV6A+j
 AYhWSKKMMdCn/IyxQ4vTddOG+mGIj8Z11328vJxpLRmBCcHxIogcyHQc8gYek8e3GN+UgBGLeCY
 l0dtvu6UsiFoZpQ==
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

