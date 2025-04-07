From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH v9 0/2] pwm: add support for NXPs high-side switch
 MC33XS2410
Date: Mon, 07 Apr 2025 13:21:50 +0200
Message-Id: <20250407-mc33xs2410-v9-0-57adcb56a6e4@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAE6182cC/0XMTQrCMBBA4auUWZuSX2pceQ9xMSbTdsA0JVEpl
 N7d4Mblt3hvh0qFqcKl26HQhyvnpcGfOggzLhMJjs2gpXbSaClSMGar2iopYlQ+2vMDPTpowVp
 o5O03u92bx5KTeM2F8L9QSsrBDM712jurhBKRE/YjxYLv65SQn33ICY7jC1nWGHqbAAAA
X-Change-ID: 20250320-mc33xs2410-dd19d48ba9a5
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dimitri Fedrau <dima.fedrau@gmail.com>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 Dimitri Fedrau <dimitri.fedrau@liebherr.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744024920; l=6622;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=THVYVAji2RQH4cDQsWSjJnLysay6oDzbDCqWSmvOAT8=;
 b=/LYfF1rXTJboEB4Cx8caI4VuqSX00mlm2Dtuap+celdIWHmiG6/kLhKPXaX6PNxKUFXq8wU/N
 bS4MMQYBBRICrt8DkQ2w6VOX2u3vnwcw4b+tZCshX2geID7qHHJYOVu
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MC33XS2410 is a four channel high-side switch. Featuring advanced
monitoring and control function, the device is operational from 3.0 V to
60 V. The device is controlled by SPI port for configuration.

Changes in V2:
  - fix title in devicetree binding
  - fix commit message in devicetree binding patch
  - remove external clock from pwms and create clocks property
  - switch to unevaluatedProperties: false
  - add missing properties for complete example:
    - pwm-names
    - pwms
    - interrupts
    - clocks

Changes in V3:
  - Add description of the general behaviour of the device (limitations)
  - Drop unused defines
  - Add ranges comments for defines with parameters
  - Drop MC33XS2410_PERIOD_MAX, MC33XS2410_PERIOD_MIN defines
  - Drop mc33xs2410_period variable
  - Round down when calculating period and duty cycle
  - Use switch instead of loop when calculating frequency
  - Removed ret variable in mc33xs2410_pwm_get_freq
  - Handle all accesses in a single call to spi_sync_transfer
  - Fix comments in function mc33xs2410_pwm_get_period
  - Fix call pwm_set_relative_duty_cycle(state, ret, 255), instead
    pwm_set_relative_duty_cycle(state, val[1] + 1, 256);
  - Use devm_pwmchip_alloc
  - Fix typo s/Transitition/Transition/
  - Drop driver_data
  - Removed patch for direct inputs from series
  - Tested with PWM_DEBUG enabled, didn't before !

Changes in V4:
  - removed include of math.h, already included in math64.h
  - removed include of mutex.h, no mutexes are used
  - added include of bitfield.h(FIELD_GET, FIELD_PREP), fixes errors
    discovered by kernel test robot
  - cast parameters in DIV_ROUND_UP to u32, fixes errors discovered by
    kernel test robot

Changes in V5:
  - Fix comment in mc33xs2410_pwm_get_freq, selecting steps instead of
    period
  - Add comment in mc33xs2410_pwm_get_relative_duty_cycle that duty_cycle
    cannot overflow and and period is not zero, guaranteed by the caller
  - Hardware emits a low level when disabled, disable if duty_cycle = 0 is
    requested.
  - Fix complaints when PWM_DEBUG enabled, round-down division in
    mc33xs2410_pwm_apply and round-up in mc33xs2410_pwm_get_state.
  - Add comment for disabling watchdog in probe

Changes in V6:
  - Add link to manual
  - Redefine MC33XS2410_GLB_CTRL_MODE_MASK as MC33XS2410_GLB_CTRL_MODE and
    MC33XS2410_GLB_CTRL_NORMAL_MODE as MC33XS2410_GLB_CTRL_MODE_NORMAL
  - Remove define MC33XS2410_MIN_PERIOD_STEP(x) as there is no need for
    parameters and use instead MC33XS2410_MIN_PERIOD
  - Rename function to_pwm_mc33xs2410_chip to mc33xs2410_from_chip
  - Add comment in mc33xs2410_pwm_get_freq why count should be rounded up
  - Fix incorrect comment in mc33xs2410_pwm_get_period
  - Rename steps variable to doubled_steps in function
    mc33xs2410_pwm_get_freq
  - remove cast in mc33xs2410_pwm_set_relative_duty_cycle
  - remove duty_cycle from if in mc33xs2410_pwm_set_relative_duty_cycle

Changes in V7:
  - Add empty lines for defines with parameter
  - Hardcode into:
    - MC33XS2410_PWM_DC1 -> MC33XS2410_PWM_DC
    - MC33XS2410_PWM_FREQ1 -> MC33XS2410_PWM_FREQ
    - MC33XS2410_MAX_PERIOD_STEP0 -> MC33XS2410_MAX_PERIOD_STEP
  - Rename:
    - MC33XS2410_MIN_PERIOD -> MC33XS2410_PWM_MIN_PERIOD
    - MC33XS2410_MAX_PERIOD_STEP -> MC33XS2410_PWM_MAX_PERIOD
    - MC33XS2410_WR -> MC33XS2410_FRAME_IN_ADDR_WR
    - MC33XS2410_RD_CTRL -> MC33XS2410_FRAME_IN_DATA_RD
    - MC33XS2410_RD_DATA_MASK -> MC33XS2410_FRAME_OUT_DATA
  - Change range for MC33XS2410_PWM_CTRL1_POL_INV
  - Drop mask suffixes
  - Switch to unsigned int len in mc33xs2410_write_regs and
    mc33xs2410_read_regs
  - Remove define MC33XS2410_WORD_LEN
  - Use a single spi transfer in mc33xs2410_write_regs and
    mc33xs2410_read_regs by using SPI_CS_WORD and 16 bits per word
  - Break the line in the argument list instead of having a static in its
    own for mc33xs2410_read_reg definition
  - Remove u32 cast mc33xs2410_pwm_get_period
  - Unroll mc33xs2410_pwm_get_relative_duty_cycle
  - Unroll mc33xs2410_pwm_set_relative_duty_cycle and remove check for
    state->enabled
  - Remove ctrl[x] and use instead a u8 flag which indicates from which
    registers to read

Changes in V8:
  - Replace x for MC33XS2410_PWM_CTRL1, MC33XS2410_PWM_CTRL3_EN,
    MC33XS2410_PWM_FREQ and MC33XS2410_PWM_DC with chan
  - Add bracketing for parameters in defines
  - Replace x for MC33XS2410_PWM_MAX_PERIOD with step
  - Add comment in mc33xs2410_pwm_apply
  - Remove hardcoded 4 with ARRAY_SIZE(reg) in:
    ret = mc33xs2410_read_regs(spi, reg, MC33XS2410_FRAME_IN_DATA_RD, val, 4);
  - Remove struct mc33xs2410_pwm and save on indirection
  - Fixed wrong bitoffset of MC33XS2410_PWM_CTRL1_POL_INV:
    BIT((chan) + 1) instead of BIT((chan) - 1)

Changes in V9:
  - Change to corporate e-mail
  - Fixed comments of defines ("s/x/chan/"):
    - MC33XS2410_PWM_CTRL1_POL_INV
    - MC33XS2410_PWM_CTRL3_EN
    - MC33XS2410_PWM_FREQ
    - MC33XS2410_PWM_DC
  - Fixed comment MC33XS2410_PWM_MAX_PERIOD "s/x/step/"
  - Replace comment in mc33xs2410_pwm_get_freq with comment suggested by Uwe
  - Rename variable freq to doubled_freq in mc33xs2410_pwm_get_period
  - Add proper handling for two cases where relative duty cyle is 0% and
    comment them in mc33xs2410_pwm_apply
  - Add comment for the reset handling

Dimitri Fedrau (2):
  dt-bindings: pwm: add support for MC33XS2410
  pwm: add support for NXPs high-side switch MC33XS2410

 .../bindings/pwm/nxp,mc33xs2410.yaml          | 118 ++++++
 drivers/pwm/Kconfig                           |  12 +
 drivers/pwm/Makefile                          |   1 +
 drivers/pwm/pwm-mc33xs2410.c                  | 378 ++++++++++++++++++
 4 files changed, 509 insertions(+)
 create mode 100644 Documentation/devicetree/bindings/pwm/nxp,mc33xs2410.yaml
 create mode 100644 drivers/pwm/pwm-mc33xs2410.c

--
2.39.5

---
Dimitri Fedrau (2):
      dt-bindings: pwm: add support for MC33XS2410
      pwm: add support for NXPs high-side switch MC33XS2410

 .../devicetree/bindings/pwm/nxp,mc33xs2410.yaml    | 118 +++++++
 drivers/pwm/Kconfig                                |  12 +
 drivers/pwm/Makefile                               |   1 +
 drivers/pwm/pwm-mc33xs2410.c                       | 391 +++++++++++++++++++++
 4 files changed, 522 insertions(+)
---
base-commit: f09762d6f6d6e81eddded89c4ae77a8b3897ab77
change-id: 20250320-mc33xs2410-dd19d48ba9a5

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

