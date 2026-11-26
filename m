From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 0/2] drm/panel: visionox-rm69299: Move off/sleep DSI
 commands to disable()
Date: Thu, 26 Nov 2026 20:57:05 +0100
Message-Id: <20261126-visionox-rm69299-enable-v2-0-d4aca6d50b05@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQ6CMBBFr0Jm7ZhSyFRceQ/DAukUJlFKWiUY0
 rtb8QAu38//728QOQhHOBcbBF4kip8y6EMB/dhNA6PYzKCVJlVrg7+KXzE8qNFNgzx1tzujIld
 ZU5EjqiGv58BO1t18bTOPEp8+vPejpfym/51LiQpdZyxpq8mezCXKsPbz6+jDAG1K6QPf5vt4w
 AAAAA==
X-Change-ID: 20260427-visionox-rm69299-enable-06f3d736f664
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Douglas Anderson <dianders@chromium.org>
Cc: =?utf-8?q?Guido_G=C3=BCnther?= <agx@sigxcpu.org>, 
 Alexander Martinz <amartinz@shiftphones.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1779; i=david@ixit.cz;
 h=from:subject:message-id; bh=zx7Xk0+dBLLt7XNzmT5ldQdB0NoABe+yn3rRzjyup5o=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrCI8T/ieL2eb52pIq9DciCixcwcUo+reruVXgG
 V8Xr6y6X0OJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawiPEwAKCRBgAj/E00kg
 cntRD/0TcjHQGiTMuRZ8wgwimLKu5mpvx5Rcyug9el5hUYhPcCc5krClaYJqmSHUWGrIncQwwZt
 /XaXnHneLkJvuD/JsAvwpDQXC8ogF8DCwGcYPw3ulNp4kwA/GYTO/m/lI5I4QYgaBD2v2+L2EA9
 0bqh1QIsx2qdmpZdHuSUaiZ5ivl5wVVZOlockQeLGVP3TjflrPclgBrTQphvoHfYk1H991udv+4
 Zj8Zt1u65Kci/L74JyHh16/ewh9paqMMlfd4bmpN9F9IDtioh/AsHO6sfAqfQsdiJOkHxDXoIs9
 CpAu/R4VRcT9/wVzZZYgGPZbTnqOmpLZQkXoMzCSdVtOQBLBqWZzzdKHoqQdmzJ5NCTBCGJoaEF
 Tpj3uyx1bBmIB6CTQEOEEbhcye61mT/ecQ4w+M2a6bQ8FoHdO6N8WvhBDFTsy7pxSGQgSp/ZBAn
 hScX9+44ihAo4QQS0DbhYI5LAJ74aXJedM9Rmag+zYxntb27uJA+yb1OGJQCDph/f9B9kG0M0WB
 Q2HgUCUOSplSslwYc32kLbxqDG+Nqesd/p5uPvCB2jObPNovv5fZzyAEFyB5gnV3bkJsYym7KVn
 1Xa7xze+Px5JKu+9pY+WjEohBapk9i7+UOh806oSpU0ReeX8qRjnH64CE7n+lSMyBp1nBVmMD7r
 BTPG1QjtIrTjwNA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On video-mode MSM DSI hosts with prepare_prev_first set, panel
unprepare() runs after the DPU timing engine has been disabled and
before the DSI host bridge post_disable() resets the video engine.
Sending DCS SET_DISPLAY_OFF in unprepare() therefore times out on every
screen blank/unblank on the SHIFT6mq:

  msm_dsi ae94000.dsi: [drm:dsi_cmds2buf_tx] *ERROR* wait for video done timed out
  dsi_cmds2buf_tx: cmd dma tx failed, type=0x5, data0=0x28, len=4, ret=-110
  panel-visionox-rm69299 ae94000.dsi.0: sending DCS SET_DISPLAY_OFF failed: -110

Move only the display-off / enter-sleep DCS commands from unprepare()
into disable() while keeping the power-on and initialization sequence in
prepare() (where the link is in LP11 before video starts), and fold
power_off() into unprepare().

---
Changes in v2:
- Keep power-on and init DSI commands in prepare() instead of moving
  them to enable() (Neil, Dmitry).
- Only fold visionox_rm69299_power_off() into unprepare(), keeping
  visionox_rm69299_power_on() for prepare() (Neil Armstrong).
- Verified on SHIFT6mq across repeated blank/unblank and
  backlight cycles with zero DSI timeouts and no stuck disp_cc clocks.
- Link to v1: https://patch.msgid.link/20260427-visionox-rm69299-enable-v1-0-fa7d62d26d87@sigxcpu.org

---
Guido Günther (2):
      drm/panel: visionox-rm69299: Move off/sleep DSI commands to disable()
      drm/panel: visionox-rm69299: Move power_off() into unprepare()

 drivers/gpu/drm/panel/panel-visionox-rm69299.c | 23 +++++++++++++----------
 1 file changed, 13 insertions(+), 10 deletions(-)
---
base-commit: 909ef7a9a30fa139e69e555e3606680f5cca7726
change-id: 20260427-visionox-rm69299-enable-06f3d736f664

Best regards,
--  
David Heidelberg <david@ixit.cz>

