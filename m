From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 0/2] Pixel 3 display fixes
Date: Mon, 10 Aug 2026 11:55:36 +0200
Message-Id: <20260810-fix-blueline-panel-v2-0-9344dfdbc3f9@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ6CMBBFr0Jm7ZhSEyquvIdh0ZapjCGFtEBQw
 t1tce/yJe+/v0GkwBThVmwQaOHIg08gTwXYTvsnIbeJQQpZiauo0fGKpp+pZ084ak89aieNsnW
 lnGwhDcdAyTqij+bHcTYvslMuZaPjOA3hfbwuZfb+HiwlCiTlLroyZEqn77zydLYfaPZ9/wLcj
 S7cxAAAAA==
X-Change-ID: 20260809-fix-blueline-panel-af2b7c967f2d
To: Sumit Semwal <sumit.semwal@linaro.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Vinod Koul <vkoul@kernel.org>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1084; i=david@ixit.cz;
 h=from:subject:message-id; bh=2WMyjEaVRWK9jzyFpbiOhg17MMA4q2ioAFM/71Fd02w=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqeaAcrio9jDiP0gaEDmcuCh6XUgMthbgEL81Ki
 3rJH0m1NtSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCanmgHAAKCRBgAj/E00kg
 con2D/99ET7GvwS5+RNu56YgtPQ7tQKhvdLgx3uBSYOjlcI4zTJJjBXxUpKfp38icet2FoR4FbV
 tUjjnR5n/zkpEvnqNghH4VRwmzlgKfvnQPOc2PdPVh01kswsnqgTLGafVnN5FaC/29nL+sD1ctE
 FmQ8m5aH7P/BglugOiprm/XZcPg+e48mZpgct47ZyNVfyDIvuZJhRuflGAJRf5DLJFmEuZrGqxy
 Awj4VkfdGW6xtJGFXnN5w8RrYdQFdgj68sKYxZVTJyElIAaZfx59nnCRhITBYWkKo4ZD0Vm04XS
 IYFQl2yTaTxXa8TmCeNp5jOK9jrJaTT6D9RiSvwy0M1RqUgzMGjlqBUMqzUmO6lyZBWKrhmCUOB
 Ne42n5/mWQLbiWHxZMkuzDSxcF+HgeJ5ni3PKnxNsi+dvVhHExrhcmJOZPjBXSq64OMVOK0wNK7
 a/cjMhnnE09oTEDgWHzXP6yiBuyuPytTDYasSKZ6ac8dnJzg+i7Q0y7wfXztXIjhdkFY2/R/wfC
 iU+J4vf+C23na3J0SF1EFydgGAGua80ju2JkDKX6sb2wuxw95rwTUjd9thdUewqUM309Jt6KkFN
 6ZI7zHa3aCV9LdCq+deroLLyzvnZRe8twoI57pBjLJQMFWFquXjgGklJLOV//NwxEZc7nlN9DjD
 ttNeuuR78/n+hmw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix panel not recovering after unprepare and backlight intensity.

I extensively reproduced the vendor bootloader sequence, but after the
boot isn't possible to do the full initialization of the display (at
least on Pixel 3, and panel can't be found anywhere else).

The downstream, due to having attached touchscreen reusing same
supplies, never turns the panel off. Let's do the same.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- Unintended change 255 -> 256 for default brigtness. Drop it.
- Added R-bs.
- Link to v1: https://patch.msgid.link/20260809-fix-blueline-panel-v1-0-e7f3a6beb1fa@ixit.cz

---
David Heidelberg (2):
      drm/panel: lg-sw43408: do not assert reset across unprepare
      drm/panel: lg-sw43408: use the full DCS brightness range

 drivers/gpu/drm/panel/panel-lg-sw43408.c | 12 +++++++++---
 1 file changed, 9 insertions(+), 3 deletions(-)
---
base-commit: 95d6a9ccef99117115e41e9adb271243bd5e985b
change-id: 20260809-fix-blueline-panel-af2b7c967f2d

Best regards,
--  
David Heidelberg <david@ixit.cz>

