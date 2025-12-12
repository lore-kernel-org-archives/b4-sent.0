From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/2] Addressing stability issues on SDM845 with the -next
 tree
Date: Sat, 13 Dec 2025 00:08:15 +0100
Message-Id: <20251213-stability-discussion-v1-0-b25df8453526@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAF+gPGkC/x2MQQqAIBAAvxJ7TsiFhPpKdDDdaiEqXIsi/HvWc
 WBmHhAKTAJt8UCgk4W3NYMuC3CzXSdS7DMDVlhr1Kgk2oEXjrfyLO6QL1Bem9FYl42qgZzugUa
 +/m3Xp/QC2Q9zMmYAAAA=
X-Change-ID: 20251212-stability-discussion-d16f6ac51209
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Petr Hodina <petr.hodina@protonmail.com>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 linux-clk@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1233; i=david@ixit.cz;
 h=from:subject:message-id; bh=t/gPYURpCIZBNgfRI56GeCxQSBGj8q9bKnexQg5Wajc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpPKBkB2JjOkLEDvLoj+opcqGrxXdDaMtPpKgXR
 tIhrpqt6CKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaTygZAAKCRBgAj/E00kg
 ciasEAC8eJf5uz/aiExjP/zuDTvmZ+Q/9/jQZ/uI9bGKZSexHfyJu4YMqro6ZTVo3SzDg3SWTaF
 24OWJcbC/P8DY7hVRrfin2Z/mA00+pd1IJ6G2i4FSQDpaDn9BPIfNiJdkTNGgii8yB7eNnFXwBj
 UrtDPm2bKMP3mSJS3NpCkUQ54HbNPvqoNJO4lG/b2tJBfE/HxZMEiLUaB+jsMhu3v2FNDfFkt0m
 Xph3VXqtYaPX01DE4jCxKf1dCtCWwbtzvwH2vX86sNcjzX4vm6FaBlUAI5Wpp67HTy2DlidGRU4
 Ncb0Uorh8heu/IwqgEx6ddqdJCVaRkQruZWbmlGIE5wcEBRt6Om1BN4JCJfZeqrNNp24GofJSKj
 GpQz4OdFzDYdT8FWrrLI+001CMvZlvb+gV4FwJ1yw+CprB5KzVXtAN/MJOtvD4h44gs8hiM2eKa
 X73+CfPOmkquTopYj+osYkXWDtt63O+HQAvzhuSsUlZr7kMQiQ1rLFErxAOYhj08s8mG4VpLfSQ
 fznB/LyXN+uRb+833vcA3rqgJVhU5HSahR/xtxDSB9iONwR8CQ2aIG6nivPw3Mx7TnUR55OVWkZ
 e9TxEJVwNsa5NHxWrokz8tmE1Mt8pzh0PZy5J0oVZEdimPfgRysNP8JVLxOQvFiLQ/LosNkGUNA
 y1iP73Gps7znU+Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We are currently running the latest linux-next snapshots (next-202511*
and next-202512*) and have encountered random freezes and crashes on the
Pixel 3, as well as crash dumps on the OnePlus 6 and 6T.

The two commits included below appear to fix, or at least work around,
the issues in our testing. We assume, however, that the underlying root
cause may still be unresolved.

We would appreciate any guidance on how best to proceed, or confirmation
that these patches are sufficient to move forward.

Thank you for your time and assistance.

Kind regards,
David and Petr

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Petr Hodina (2):
      drm/msm/dpu: Add NULL pointer check in dpu_crtc_duplicate_state()
      clk: qcom: rcg2, msm/dsi: Fix hangs caused by register writes while clocks are off

 drivers/clk/qcom/clk-rcg2.c              | 18 ++++++++++++++++++
 drivers/gpu/drm/msm/disp/dpu1/dpu_crtc.c |  7 ++++++-
 drivers/gpu/drm/msm/dsi/dsi_host.c       | 13 +++++++++++++
 3 files changed, 37 insertions(+), 1 deletion(-)
---
base-commit: d9771d0dbe18dd643760431870a6abf9b0866bb0
change-id: 20251212-stability-discussion-d16f6ac51209

Best regards,
-- 
David Heidelberg <david@ixit.cz>

