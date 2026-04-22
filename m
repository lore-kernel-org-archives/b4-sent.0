From: David Heidelberg <david@ixit.cz>
Subject: [PATCH RESEND 0/4] drm/panel: Small Kconfig cleanup
Date: Wed, 22 Apr 2026 11:48:34 +0200
Message-Id: <20260422-panel-clean-up-kconfig-dep-v1-0-d825e9ffe911@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Dzmitry Sankouski <dsankouski@gmail.com>, Sam Ravnborg <sam@ravnborg.org>
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 marijn.suijten@somainline.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=763; i=david@ixit.cz;
 h=from:subject:message-id; bh=ylQzySUo9bDhSqmkcXiDS7XuuRz2rDXvl6KfxBGmTsY=;
 b=kA0DAAgBYAI/xNNJIHIByyZiAGnomXih2X9v8Bfun+gaoBwp9eFzTbvsiKUw650qXY3DOpNqc
 IkCMwQAAQgAHRYhBNd6Cc/u3Cu9U6cEdGACP8TTSSByBQJp6Jl4AAoJEGACP8TTSSByfj8QALSE
 kxyBpbLRU7LCBQKbXXvtnVh0TMNEWO7u209TXCRBeMXcx53ZcI3PIwj5FDsXC1qtabCsQnyKyc6
 t5TLPgcsxDtpgpGRPGrsV5mlPCT/mPvME9iZ7d/XYqwpfuvOumYAc9ac2h78Ml32sxlF612dO+b
 7wLgFuYKP3m0Ap8WetqodFqqHeKJP2ZNAYFY2ARcHs87Dx3bFYAWYs0+ndTYKvtUwMNT013ZtSX
 i/35mLVSSfiJWqJy2oyQIgfunTm94zdAxgWulIv5rqamGSD+L7M/SjbLmfPOlS/Z6zOu1ga+eHE
 vWkrZiIoGDdSUq2oIqKjrmWTA//9N3o4WHrsjzrBccNBNko9xfw7F5K+DwQ/0z5PnCb25Nlsilw
 eqxLVAuQzK07mbxZncDUC9PD8CW58rdjQJw9JA1MLN0fluolVDE8toOVHgQdOKHQE6FMf5j8q6i
 wbMtbL4zc325UM63dDdSdrFT9eOqSxGgd7og+WNenJZrA36kUEOmb2NE6zrhxIGWr5Mn/A3XweX
 CtJNcdT9BPGQ0TZvmGfdF8zXs3ZzU5y7aTfjYaHThVZJarwWD7qrSApCiAkGQ1OiAuZq3qRrAPa
 8OGUHk2Hav1zkBTpLHL7AMMzAcxvzIJD8R1JAcxSwGewW1nNglyeiRmrwcjue8AvhpykRm+FwE3
 DJn4x
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Inspired by looking at Marijn patch. Since Marijn patch is not merged yet,
appending patch to my series.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (3):
      drm/panel: Clean up S6E3FC2X01 config dependencies
      drm/panel: Clean up S6E3HA2 config dependencies and fill help text
      drm/panel: Enable GPIOLIB for panels which uses functions from it

Marijn Suijten (1):
      drm/panel: Clean up SOFEF00 config dependencies

 drivers/gpu/drm/panel/Kconfig | 25 +++++++++++++++----------
 1 file changed, 15 insertions(+), 10 deletions(-)
---
base-commit: 877552aa875839314afad7154b5a561889e87ea9
change-id: 20260224-panel-clean-up-kconfig-dep-7dc39c351ef8

Best regards,
-- 
David Heidelberg <david@ixit.cz>

