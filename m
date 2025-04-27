From: Kurt Borja <kuurtb@gmail.com>
Date: Sun, 27 Apr 2025 03:24:49 -0300
Subject: [PATCH v2 2/2] Documentation: wmi: alienware-wmi: Add GPIO control
 documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250427-awcc-gpio-v2-2-c731373b5d02@gmail.com>
References: <20250427-awcc-gpio-v2-0-c731373b5d02@gmail.com>
In-Reply-To: <20250427-awcc-gpio-v2-0-c731373b5d02@gmail.com>
To: Hans de Goede <hdegoede@redhat.com>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Armin Wolf <W_Armin@gmx.de>
Cc: Gabriel Marcano <gabemarcano@yahoo.com>, 
 platform-driver-x86@vger.kernel.org, Dell.Client.Kernel@dell.com, 
 linux-kernel@vger.kernel.org, Kurt Borja <kuurtb@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5285; i=kuurtb@gmail.com;
 h=from:subject:message-id; bh=zC8+gJDq11VBsTxTMVnO6aUkwcVu2ZYewNrS8rkQd+k=;
 b=owGbwMvMwCUmluBs8WX+lTTG02pJDBm8Z8+4+7vMOnyoK9+6QtPZIvq0nU+WWtNaRYmdT+u3Z
 3LZ9p7rKGVhEONikBVTZGlPWPTtUVTeW78Dofdh5rAygQxh4OIUgIkcuMPwT99iWi4b75XcjcLi
 AS+1fjak/A5cZZO9JphHRrjR8LjzRkaGv2fu50VNfPWs4b3Y7zdLZAOSEi/efqaew37ni7aVaZQ
 qHwA=
X-Developer-Key: i=kuurtb@gmail.com; a=openpgp;
 fpr=54D3BE170AEF777983C3C63B57E3B6585920A69A
X-Endpoint-Received: by B4 Relay for kuurtb@gmail.com/default with auth_id=387
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add documentation for the GPIO control methods.

Signed-off-by: Kurt Borja <kuurtb@gmail.com>
---
 Documentation/wmi/devices/alienware-wmi.rst | 78 +++++++++++++++++++++++++++--
 1 file changed, 74 insertions(+), 4 deletions(-)

diff --git a/Documentation/wmi/devices/alienware-wmi.rst b/Documentation/wmi/devices/alienware-wmi.rst
index 79238051b18bc5de9b502325017cd5c5fcf41748..2a6052efb9ae0e3fe0a5d9d5775073234dfc96fb 100644
--- a/Documentation/wmi/devices/alienware-wmi.rst
+++ b/Documentation/wmi/devices/alienware-wmi.rst
@@ -231,6 +231,70 @@ WMI method MemoryOCControl([in] uint32 arg2, [out] uint32 argr)
 AWCC supports memory overclocking, but this method is very intricate and has
 not been deciphered yet.
 
+GPIO control Methods
+====================
+
+Alienware and Dell G Series devices with the AWCC interface usually have an
+embedded STM32 RGB lighting controller with USB/HID capabilities. It's vendor ID
+is ``187c`` while it's product ID may vary from model to model.
+
+The control of two GPIO pins of this MCU is exposed as WMI methods for debugging
+purposes.
+
++--------------+--------------------------------------------------------------+
+| Pin          | Description                                                  |
++==============+===============================+==============================+
+| 0            | Device Firmware Update (DFU)  | **HIGH**: Enables DFU mode   |
+|              | mode pin.                     | on next MCU boot.            |
+|              |                               +------------------------------+
+|              |                               | **LOW**: Disables DFU mode   |
+|              |                               | on next MCU boot.            |
++--------------+-------------------------------+------------------------------+
+| 1            | Negative Reset (NRST) pin.    | **HIGH**: MCU is ON.         |
+|              |                               |                              |
+|              |                               +------------------------------+
+|              |                               | **LOW**: MCU is OFF.         |
+|              |                               |                              |
++--------------+-------------------------------+------------------------------+
+
+See :ref:`acknowledgements` for more information on this MCU.
+
+.. note::
+   Some GPIO control methods break the usual argument structure and take a
+   **Pin number** instead of an operation on the first byte.
+
+WMI method FWUpdateGPIOtoggle([in] uint32 arg2, [out] uint32 argr)
+------------------------------------------------------------------
+
++--------------------+------------------------------------+--------------------+
+| Operation (Byte 0) | Description                        | Arguments          |
++====================+====================================+====================+
+| Pin number         | Set the pin status                 | - Byte 1: Pin      |
+|                    |                                    |   status           |
++--------------------+------------------------------------+--------------------+
+
+WMI method ReadTotalofGPIOs([out] uint32 argr)
+----------------------------------------------
+
++--------------------+------------------------------------+--------------------+
+| Operation (Byte 0) | Description                        | Arguments          |
++====================+====================================+====================+
+| 0x00               | Get the total number of GPIOs      | - None             |
++--------------------+------------------------------------+--------------------+
+
+WMI method ReadGPIOpPinStatus([in] uint32 arg2, [out] uint32 argr)
+------------------------------------------------------------------
+
++--------------------+------------------------------------+--------------------+
+| Operation (Byte 0) | Description                        | Arguments          |
++====================+====================================+====================+
+| Pin number         | Get the pin status                 | - None             |
++--------------------+------------------------------------+--------------------+
+
+.. note::
+   There known firmware bug in some laptops where reading the status of a pin
+   also flips it.
+
 Other information Methods
 =========================
 
@@ -239,10 +303,16 @@ WMI method ReadChassisColor([out] uint32 argr)
 
 Returns the chassis color internal ID.
 
+.. _acknowledgements:
+
 Acknowledgements
 ================
 
-Kudos to `AlexIII <https://github.com/AlexIII/tcc-g15>`_ and
-`T-Troll <https://github.com/T-Troll/alienfx-tools/>`_ for documenting and
-testing some of this device's functionality, making it possible to generalize
-this driver.
+Kudos to
+
+* `AlexIII <https://github.com/AlexIII/tcc-g15>`_
+* `T-Troll <https://github.com/T-Troll/alienfx-tools/>`_
+* `Gabriel Marcano <https://gabriel.marcanobrady.family/blog/2024/12/16/dell-g5-5505-se-acpi-or-figuring-out-how-to-reset-the-rgb-controller/>`_
+
+for documenting and testing some of this device's functionality, making it
+possible to generalize this driver.

-- 
2.49.0

