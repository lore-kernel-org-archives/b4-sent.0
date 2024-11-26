From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:22:26 -0800
Subject: [PATCH 36/36] docs/misc: update console documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-36-87b9a8375b7a@ford.com>
References: <20241126-vuart-ns8250-v1-v1-0-87b9a8375b7a@ford.com>
In-Reply-To: <20241126-vuart-ns8250-v1-v1-0-87b9a8375b7a@ford.com>
To: Jan Beulich <jbeulich@suse.com>, 
 Andrew Cooper <andrew.cooper3@citrix.com>, 
 =?utf-8?q?Roger_Pau_Monn=C3=A9?= <roger.pau@citrix.com>, 
 "Daniel P. Smith" <dpsmith@apertussolutions.com>, 
 Stefano Stabellini <sstabellini@kernel.org>, Julien Grall <julien@xen.org>, 
 Bertrand Marquis <bertrand.marquis@arm.com>, 
 Michal Orzel <michal.orzel@amd.com>, Rahul Singh <rahul.singh@arm.com>, 
 Volodymyr Babchuk <Volodymyr_Babchuk@epam.com>, 
 Alistair Francis <alistair.francis@wdc.com>, 
 Bob Eshleman <bobbyeshleman@gmail.com>, 
 Connor Davis <connojdavis@gmail.com>, 
 Oleksii Kurochko <oleksii.kurochko@gmail.com>, 
 Shawn Anastasio <sanastasio@raptorengineering.com>, 
 Anthony PERARD <anthony.perard@vates.tech>, Juergen Gross <jgross@suse.com>, 
 Christian Lindig <christian.lindig@citrix.com>, 
 David Scott <dave@recoil.org>, 
 =?utf-8?q?Marek_Marczykowski-G=C3=B3recki?= <marmarek@invisiblethingslab.com>
Cc: xen-devel@lists.xenproject.org, Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=5611;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=O/e2TuAbfREf6sK5Rox2Z4H+zlo5Q3N8ksFZglsK7sE=;
 b=XavKhjZA3mfK4h09UVfAzuoD+nqYtkqc4418biMqkmSexlVgea/EgM0/sVOixRT0rGc6Is/Ke
 gmcR6+YgzKOD7ftpuWh53AGZUZYrdt+D/f3ZpAPz7y6T7Ams0JNWAsX
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Minor update related to virtual UART support.

Also:
 s/pv/PV/g
 s/hvm/HVM/g

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 docs/misc/console.txt | 48 +++++++++++++++++++++++++-----------------------
 1 file changed, 25 insertions(+), 23 deletions(-)

diff --git a/docs/misc/console.txt b/docs/misc/console.txt
index 4e180f88ba1312d8fcc47d27622ec347d387ce12..b5411b4d74b6d3d920a4fbb2ce6033a239ec5832 100644
--- a/docs/misc/console.txt
+++ b/docs/misc/console.txt
@@ -4,11 +4,11 @@ Xen PV Console notes
                                         stefano.stabellini@eu.citrix.com
 
 
-Xen traditionally provided a single pv console to pv guests, storing the
+Xen traditionally provided a single PV console to PV guests, storing the
 relevant information in xenstore under /local/domain/$DOMID/console.
 
-Now many years after the introduction of the pv console we have
-multiple pv consoles support for pv and hvm guests; multiple pv
+Now many years after the introduction of the PV console we have
+multiple PV consoles support for PV and HVM guests; multiple PV
 console backends (qemu and xenconsoled, see limitations below) and
 emulated serial cards too.
 
@@ -103,48 +103,50 @@ The supported values are only xenconsoled or ioemu; xenconsoled has
 several limitations: it can only be used for the first PV or virtual UART
 console and it can only connect to a pty.
 
-Emulated serials are provided by qemu-dm only to hvm guests; the number
-of emulated serials depends on how many "-serial" command line options
-are given to qemu. The output of a serial is specified as argument to
-the -serial command line option to qemu. Qemu writes the tty name to
-xenstore in the following path:
+Emulated serials are provided to HVM guests by qemu-dm or in-hypervisor UART
+emulator (Xen needs to be re-compiled).
+
+In qemu-dm case, the number of emulated serials depends on how many "-serial"
+command line options are given to qemu. The output of a serial is specified as
+argument to the -serial command line option to qemu. Qemu writes the tty name
+to xenstore in the following path:
 
 /local/domain/$DOMID/serial/$SERIAL_NUM/tty
 
 xenconsole is the tool to connect to a PV or virtual UART console or an
 emulated serial that has a pty as output. Xenconsole takes a domid as
-parameter plus an optional console type (pv for PV consoles, vuart for
+parameter plus an optional console type (PV for PV consoles, vuart for
 virtual UART or serial for emulated serials) and console number.
 Depending on the type and console number, xenconsole will look for the tty
 node in different xenstore paths, as described above.  If the user doesn't
-specify the console type xenconsole will try to guess: if the guest is a pv
-guest it defaults to PV console, if the guest is an hvm guest it defaults to
+specify the console type xenconsole will try to guess: if the guest is a PV
+guest it defaults to PV console, if the guest is an HVM guest it defaults to
 emulated serial.
 
-By default xl creates a pv console for hvm guests, plus an emulated
+By default xl creates a PV console for HVM guests, plus an emulated
 serial if the user specified 'serial = "pty"' in the VM config file.
-Considering that xenconsole defaults to emulated serials for hvm guests,
+Considering that xenconsole defaults to emulated serials for HVM guests,
 executing xl create -c "domain" causes xenconsole to attach to the
 emulated serial tty. This is most probably what the user wanted because
-currently no bootloaders support xen pv consoles so the only way to
+currently no bootloaders support xen PV consoles so the only way to
 interact with a bootloader like grub over a console is to use the
 emulated serial.
-However the pv console is still easy to use with Linux PV on HVM guests:
+However the PV console is still easy to use with Linux PV on HVM guests:
 the user just need to pass "console=hvc0" to the kernel command line and
 then execute "xl console -t pv <domain>" to connect to it.
 
 When using stubdoms the serial cards are still emulated by qemu (this
 time running in the stubdom), the number of serial cards and where the
 output goes is still specified using qemu command line options.
-The difference is that for each emulated serial card there must be a pv
+The difference is that for each emulated serial card there must be a PV
 console connection between the stubdom and dom0 to export the serial
-output from the stubdom to dom0. The pv console backend for stubdom's pv
-consoles is always ioemu because multiple pv consoles support is a
-requirement in this case, considering that minios has its own pv console
-too. In order to simplify the setup when using stubdoms the hvm guest
-can only have one pv console with xenstored as backend (the stubdom
-could provide pv console backends to the hvm guest but then it would
-need another pv console connection for each console backend to export
+output from the stubdom to dom0. The PV console backend for stubdom's PV
+consoles is always ioemu because multiple PV consoles support is a
+requirement in this case, considering that minios has its own PV console
+too. In order to simplify the setup when using stubdoms the HVM guest
+can only have one PV console with xenstored as backend (the stubdom
+could provide PV console backends to the HVM guest but then it would
+need another PV console connection for each console backend to export
 the pty to dom0).
 
 The xenconsole program supports a very simple protocol to notify parent about

-- 
2.34.1

