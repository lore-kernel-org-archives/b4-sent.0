From: Casey Connolly <casey.connolly@linaro.org>
Subject: [PATCH 0/2] qcom: gracefully handle some errors better
Date: Fri, 20 Mar 2026 16:45:39 +0100
Message-Id: <20260320-casey-qcom-rpmh-serial-fixes-v1-0-b81d05832eec@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKNrvWkC/yXMywqDQAyF4VeRrA3MBSz1VaSLmRg1pd4mtrSI7
 96xXf4czreDchJWqIsdEr9EZZ5y2LIAGsLUM0qbG5xxlfHOIAXlD640j5iWccDzHx7YyZsV21h
 ZF+hytT5CJpbEvyELze3f+ox3pu004Ti+B3wreIAAAAA=
X-Change-ID: 20260320-casey-qcom-rpmh-serial-fixes-db612ac7913b
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Andrew Goodbody <andrew.goodbody@linaro.org>, 
 Stephen Boyd <swboyd@chromium.org>
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=openpgp-sha256; l=1016;
 i=casey.connolly@linaro.org; h=from:subject:message-id;
 bh=FRk0ouKnTihbQvqV+MBTZ5o9/3BCFR9eGQSLL+tJRUs=;
 b=owGbwMvMwCFYaeA6f6eBkTjjabUkhsy92avjLbJ7H3519l1w+M2xWOt1XPMuOEj3vK2r0jxSs
 vzQJ6tPHaUsDIIcDLJiiiziJ5ZZNq29bK+xfcEFmDmsTCBDGLg4BWAidyYz/He+ITm9JXTnjq2p
 05f3h+39svts3SWTzRf6//n6rhUL0t7KyLAnL6D6zUG5KOPKaWoCbDPW/9rT3JNSEJS6mvPa9J7
 zK98CAA==
X-Developer-Key: i=casey.connolly@linaro.org; a=openpgp;
 fpr=83B24DA7FE145076BC38BB250CD904EB673A7C47
X-Endpoint-Received: by B4 Relay for casey.connolly@linaro.org/default with auth_id=688
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adjust the serial driver to not bail out if we can't find the clock,
this could happen pre-relocation if the clock driver isn't bound or if
there is no clock driver yet. In most cases this isn't an issue since
the clocks are left enabled by the previous bootloader stage.

Additionally adjust the rpmh driver to gracefully bail out for
non-active write requests, sleep/wake votes are meaningless in U-Boot
since we will always be in the active state. It's possible that the
caller may send an active rpmh write after the sleep request but might
not if we return an error, so let's play it safe.

---
Casey Connolly (2):
      serial: msm-geni: allow invalid clock
      qcom: rpmh: don't error for SLEEP requests

 drivers/serial/serial_msm_geni.c | 15 +++++----------
 drivers/soc/qcom/rpmh-rsc.c      |  8 ++++----
 drivers/soc/qcom/rpmh.c          |  4 ++--
 3 files changed, 11 insertions(+), 16 deletions(-)
---
base-commit: ba7bf918dafcd093ad733b07ba490baeb20cf5da

// Casey (she/they)

