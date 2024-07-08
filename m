From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 08 Jul 2024 14:43:23 +0100
Subject: [PATCH kmod v2 15/17] man: remove the "Maintained by" references
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240708-man-v2-15-a23df6ef871e@gmail.com>
References: <20240708-man-v2-0-a23df6ef871e@gmail.com>
In-Reply-To: <20240708-man-v2-0-a23df6ef871e@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720446209; l=3766;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=oazsCu1x5cpTjLe811bZRP1oyu3WkDozVetIymM8AT0=;
 b=ThGjE1GWa8Iw/bD5WDDOlIsR5iHEjAp5Nz93qqh1qzn3n/9GOR80t2QkldWaB4fVlezYm3SKO
 9KuqrYaX+9HC7dtFabdVUKH4J8+MBDb+vX8aunSVCRF98F83bLv0Dmn
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

At a glance through my system, around 2% of the man pages include such
statement.

Looking through git log, Jon has been active in a while and presumably
have moved on.

Most importantly the Copyright section isn't the best place to reference
the maintainer/contact person.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
Instead we can add a note in the authors section, pointing people to the
ML/kernel.org/Github repo for when seeking contact.

Also should probably s/Developer/Maintainer/ for Lucas, who's been
keeping the project afloat the last few decades ;-)

Lucas, what do you think?
---
 man/insmod.8.scd      | 1 -
 man/kmod.8.scd        | 3 +--
 man/lsmod.8.scd       | 1 -
 man/modinfo.8.scd     | 1 -
 man/modprobe.8.scd    | 1 -
 man/modprobe.d.5.scd  | 1 -
 man/modules.dep.5.scd | 1 -
 man/rmmod.8.scd       | 1 -
 8 files changed, 1 insertion(+), 9 deletions(-)

diff --git a/man/insmod.8.scd b/man/insmod.8.scd
index b6f8654..27d4409 100644
--- a/man/insmod.8.scd
+++ b/man/insmod.8.scd
@@ -21,7 +21,6 @@ information about errors.
 # COPYRIGHT
 
 This manual page originally Copyright 2002, Rusty Russell, IBM Corporation.
-Maintained by Jon Masters and others.
 
 # SEE ALSO
 
diff --git a/man/kmod.8.scd b/man/kmod.8.scd
index 2007a2d..6bd9432 100644
--- a/man/kmod.8.scd
+++ b/man/kmod.8.scd
@@ -35,8 +35,7 @@ Linux Kernel modules. Most users will only run it using its other names.
 
 # COPYRIGHT
 
-This manual page originally Copyright 2014, Marco d'Itri. Maintained by Lucas De
-Marchi and others.
+This manual page originally Copyright 2014, Marco d'Itri.
 
 # SEE ALSO
 
diff --git a/man/lsmod.8.scd b/man/lsmod.8.scd
index eb2f2e8..ded619e 100644
--- a/man/lsmod.8.scd
+++ b/man/lsmod.8.scd
@@ -15,7 +15,6 @@ lsmod - Show the status of modules in the Linux Kernel
 # COPYRIGHT
 
 This manual page originally Copyright 2002, Rusty Russell, IBM Corporation.
-Maintained by Jon Masters and others.
 
 # SEE ALSO
 
diff --git a/man/modinfo.8.scd b/man/modinfo.8.scd
index 9545257..d088c7e 100644
--- a/man/modinfo.8.scd
+++ b/man/modinfo.8.scd
@@ -63,7 +63,6 @@ architecture.
 # COPYRIGHT
 
 This manual page originally Copyright 2003, Rusty Russell, IBM Corporation.
-Maintained by Jon Masters and others.
 
 # SEE ALSO
 
diff --git a/man/modprobe.8.scd b/man/modprobe.8.scd
index 30ccc21..67cbb1a 100644
--- a/man/modprobe.8.scd
+++ b/man/modprobe.8.scd
@@ -201,7 +201,6 @@ rules.
 # COPYRIGHT
 
 This manual page originally Copyright 2002, Rusty Russell, IBM Corporation.
-Maintained by Jon Masters and others.
 
 # SEE ALSO
 
diff --git a/man/modprobe.d.5.scd b/man/modprobe.d.5.scd
index b7b1942..246457b 100644
--- a/man/modprobe.d.5.scd
+++ b/man/modprobe.d.5.scd
@@ -167,7 +167,6 @@ directly within the modules.
 # COPYRIGHT
 
 This manual page originally Copyright 2004, Rusty Russell, IBM Corporation.
-Maintained by Jon Masters and others.
 
 # SEE ALSO
 
diff --git a/man/modules.dep.5.scd b/man/modules.dep.5.scd
index c4e7653..7723a16 100644
--- a/man/modules.dep.5.scd
+++ b/man/modules.dep.5.scd
@@ -29,7 +29,6 @@ fashion rather than touching these files.
 # COPYRIGHT
 
 This manual page originally Copyright 2002, Rusty Russell, IBM Corporation.
-Maintained by Jon Masters and others.
 
 # SEE ALSO
 
diff --git a/man/rmmod.8.scd b/man/rmmod.8.scd
index e1f656f..c4dcc3e 100644
--- a/man/rmmod.8.scd
+++ b/man/rmmod.8.scd
@@ -35,7 +35,6 @@ is provided) from the kernel. Most users will want to use *modprobe*(8) with the
 # COPYRIGHT
 
 This manual page originally Copyright 2002, Rusty Russell, IBM Corporation.
-Maintained by Jon Masters and others.
 
 # SEE ALSO
 

-- 
2.45.2

