From: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
Date: Sun, 22 Nov 2026 13:08:46 -0300
Subject: [PATCH 4/4] docs/translations/pt_BR: process: add
 maintainer-pgp-guide.rst (4/4)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261122-maintainer-pgp-guide-pt-br-v1-4-01ce5941c5c2@gmail.com>
References: <20261122-maintainer-pgp-guide-pt-br-v1-0-01ce5941c5c2@gmail.com>
In-Reply-To: <20261122-maintainer-pgp-guide-pt-br-v1-0-01ce5941c5c2@gmail.com>
To: linux-doc@vger.kernel.org
Cc: danielmaraboo@gmail.com, corbet@lwn.net, skhan@linuxfoundation.org, 
 rdunlap@infradead.org, Eduardo Pereira Cruz <dreduardocruz@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795363722; l=13809;
 i=dreduardocruz@gmail.com; s=20261119; h=from:subject:message-id;
 bh=WwZO9kC3rRbNLX5y6rS6DaDwrlIsnNblflitUqGr970=;
 b=EFBGIVkYy+6GZ5UXqn7yc66x5HGhBgOURhvj/egb5GV95i84tSu3B/dOI0DObRi+EUqBBtyaH
 6Ez2Vv+2eg7BxLFFJlkboqOseKz6fiDE4ImwqbNIzGHS3v29D+CR/xa
X-Developer-Key: i=dreduardocruz@gmail.com; a=ed25519;
 pk=2dtL+BL/x70sROmAvlskv9dbjj274zlPkLBVu4gJJiA=
X-Endpoint-Received: by B4 Relay for dreduardocruz@gmail.com/20261119 with auth_id=1571
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Finish the translation with the Git integration chapter (signed tags
and commits, patatt) and the section on verifying kernel developer
identities (WKD, DANE, TOFU and the kernel.org keyring).

Signed-off-by: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
---
 Documentation/translations/pt_BR/process/index.rst |   1 +
 .../pt_BR/process/maintainer-pgp-guide.rst         | 276 +++++++++++++++++++++
 2 files changed, 277 insertions(+)

diff --git a/Documentation/translations/pt_BR/process/index.rst b/Documentation/translations/pt_BR/process/index.rst
index d072f7e46767..a612b22e267c 100644
--- a/Documentation/translations/pt_BR/process/index.rst
+++ b/Documentation/translations/pt_BR/process/index.rst
@@ -46,6 +46,7 @@ devem estar familiarizados.
    Adicionando uma nova chamada de Sistema <adding-syscalls>
    Por que a classe de tipo "volatile" não deve ser usada <volatile-considered-harmful>
    Como não Deixar as ioctls malfeitas <botching-up-ioctls>
+   Guia de PGP para mantenedores <maintainer-pgp-guide>
 
 Guias de políticas e declarações de desenvolvedores
 ---------------------------------------------------
diff --git a/Documentation/translations/pt_BR/process/maintainer-pgp-guide.rst b/Documentation/translations/pt_BR/process/maintainer-pgp-guide.rst
index 7808ef4730ae..8cec13c6559b 100644
--- a/Documentation/translations/pt_BR/process/maintainer-pgp-guide.rst
+++ b/Documentation/translations/pt_BR/process/maintainer-pgp-guide.rst
@@ -644,3 +644,279 @@ outra ponta.
 
 .. _pgp_with_git:
 
+Usando PGP com o Git
+====================
+
+Uma das características centrais do Git é a sua natureza descentralizada --
+uma vez que um repositório é clonado no seu sistema, você tem o histórico
+completo do projeto, incluindo todas as suas tags, commits e ramos. No
+entanto, com centenas de repositórios clonados circulando, como alguém
+verifica que a sua cópia do linux.git não foi adulterada por um terceiro
+malicioso?
+
+Ou o que acontece se um código malicioso for descoberto no kernel e a linha
+"Author" do commit disser que foi você quem fez, enquanto você tem quase
+certeza de que `não teve nada a ver com isso`_?
+
+Para resolver essas duas questões, o Git introduziu a integração com PGP. Tags
+assinadas provam a integridade do repositório ao assegurar que o seu conteúdo
+é exatamente o mesmo da estação de trabalho do desenvolvedor que criou a tag,
+enquanto commits assinados tornam quase impossível alguém se passar por você
+sem ter acesso às suas chaves PGP.
+
+.. _`não teve nada a ver com isso`: https://github.com/jayphelps/git-blame-someone-else
+
+Configure o Git para usar a sua chave PGP
+-----------------------------------------
+
+Se você tem apenas uma chave secreta no seu chaveiro, não precisa fazer nada
+extra, pois ela se torna a sua chave padrão. Porém, se tiver várias chaves
+secretas, você pode dizer ao Git qual chave deve ser usada (``[fpr]`` é a
+impressão digital da sua chave)::
+
+    $ git config --global user.signingKey [fpr]
+
+Como trabalhar com tags assinadas
+---------------------------------
+
+Para criar uma tag assinada, passe a opção ``-s`` ao comando tag::
+
+    $ git tag -s [tagname]
+
+Nossa recomendação é sempre assinar as tags do Git, pois isso permite que
+outros desenvolvedores verifiquem que o repositório Git de onde estão puxando
+não foi alterado maliciosamente.
+
+Como verificar tags assinadas
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+Para verificar uma tag assinada, use o comando ``verify-tag``::
+
+    $ git verify-tag [tagname]
+
+Se você estiver puxando uma tag de outro fork do repositório do projeto, o Git
+deve verificar automaticamente a assinatura na ponta que você está puxando e
+mostrar os resultados durante a operação de merge::
+
+    $ git pull [url] tags/sometag
+
+A mensagem de merge conterá algo como isto::
+
+    Merge tag 'sometag' of [url]
+    [Tag message]
+
+    # gpg: Signature made [...]
+    # gpg: Good signature from [...]
+
+Se você estiver verificando a tag Git de outra pessoa, primeiro precisará
+importar a chave PGP dela. Consulte a seção ":ref:`verify_identities`"
+abaixo.
+
+Configure o Git para sempre assinar tags anotadas
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+É provável que, se você está criando uma tag anotada, queira assiná-la. Para
+forçar o Git a sempre assinar tags anotadas, defina uma opção de configuração
+global::
+
+    $ git config --global tag.forceSignAnnotated true
+
+Como trabalhar com commits assinados
+------------------------------------
+
+Também é possível criar commits assinados, mas eles têm utilidade limitada no
+desenvolvimento do kernel Linux. O fluxo de contribuição do kernel baseia-se
+no envio de patches, e converter commits em patches não preserva as
+assinaturas de commit do Git. Além disso, ao rebasear o seu próprio repositório
+sobre um upstream mais novo, as assinaturas PGP de commit acabam descartadas.
+Por essa razão, a maioria dos desenvolvedores do kernel não se dá ao trabalho
+de assinar os seus commits e ignora commits assinados em quaisquer
+repositórios externos nos quais se apoiam no trabalho.
+
+Dito isso, se você tem a sua árvore Git de trabalho disponível publicamente em
+algum serviço de hospedagem Git (kernel.org, infradead.org, ozlabs.org ou
+outros), então a recomendação é assinar todos os seus commits Git, mesmo que
+os desenvolvedores upstream não se beneficiem diretamente da prática.
+
+Recomendamos isso pelas seguintes razões:
+
+1. Caso algum dia haja necessidade de fazer perícia de código ou rastrear a
+   proveniência do código, mesmo árvores mantidas externamente que carreguem
+   assinaturas PGP de commit serão valiosas para tais propósitos.
+2. Se você precisar reclonar o seu repositório local (por exemplo, após
+   reinstalar o sistema), isso permite verificar a integridade do repositório
+   antes de retomar o trabalho.
+3. Se alguém precisar fazer cherry-pick dos seus commits, isso permite
+   verificar rapidamente a integridade deles antes de aplicá-los.
+
+Criando commits assinados
+~~~~~~~~~~~~~~~~~~~~~~~~~
+
+Para criar um commit assinado, passe a opção ``-S`` ao comando
+``git commit`` (é ``-S`` maiúsculo por colisão com outra opção)::
+
+    $ git commit -S
+
+Configure o Git para sempre assinar commits
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+Você pode dizer ao Git para sempre assinar commits::
+
+    git config --global commit.gpgSign true
+
+.. note::
+
+    Não deixe de configurar o ``gpg-agent`` antes de ativar esta opção.
+
+.. _verify_identities:
+
+Como trabalhar com patches assinados
+-------------------------------------
+
+É possível usar a sua chave PGP para assinar patches enviados às listas de
+discussão de desenvolvedores do kernel. Como os mecanismos existentes de
+assinatura de e-mail (PGP-Mime ou PGP-inline) costumam causar problemas nas
+tarefas normais de revisão de código, você deve usar a ferramenta criada pelo
+kernel.org para esse propósito, que coloca assinaturas de atestação
+criptográfica nos cabeçalhos das mensagens (ao estilo DKIM):
+
+- `Patatt Patch Attestation`_
+
+.. _`Patatt Patch Attestation`: https://pypi.org/project/patatt/
+
+Instalando e configurando o patatt
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+.. note::
+
+    Se você usa o B4 para enviar os seus patches, o patatt já está instalado
+    e integrado ao seu fluxo de trabalho.
+
+O patatt já está empacotado para muitas distribuições, então verifique lá
+primeiro. Você também pode instalá-lo a partir do pypi usando
+"``pip install patatt``".
+
+Se você já tem a sua chave PGP configurada com o Git (via o parâmetro de
+configuração ``user.signingKey``), então o patatt não requer configuração
+adicional. Você pode começar a assinar os seus patches instalando o hook do
+git-send-email no repositório que quiser::
+
+    patatt install-hook
+
+Agora quaisquer patches que você enviar com ``git send-email`` serão
+automaticamente assinados com a sua assinatura criptográfica.
+
+Verificando assinaturas do patatt
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+Se você usa o ``b4`` para obter e aplicar patches, ele tentará automaticamente
+verificar todas as assinaturas DKIM e patatt que encontrar, por exemplo::
+
+    $ b4 am 20220720205013.890942-1-broonie@kernel.org
+    [...]
+    Checking attestation on all messages, may take a moment...
+    ---
+      ✓ [PATCH v1 1/3] kselftest/arm64: Correct buffer allocation for SVE Z registers
+      ✓ [PATCH v1 2/3] arm64/sve: Document our actual ABI for clearing registers on syscall
+      ✓ [PATCH v1 3/3] kselftest/arm64: Enforce actual ABI for SVE syscalls
+      ---
+      ✓ Signed: openpgp/broonie@kernel.org
+      ✓ Signed: DKIM/kernel.org
+
+.. note::
+
+    O patatt e o b4 ainda estão em desenvolvimento ativo; consulte a
+    documentação mais recente desses projetos para recursos novos ou
+    atualizados.
+
+.. _kernel_identities:
+
+Como verificar identidades de desenvolvedores do kernel
+=======================================================
+
+Assinar tags e commits é direto, mas como se faz para verificar que a chave
+usada para assinar algo pertence ao desenvolvedor real do kernel e não a um
+impostor malicioso?
+
+Configure a recuperação automática de chaves com WKD e DANE
+----------------------------------------------------------
+
+Se você ainda não é alguém com uma coleção extensa de chaves públicas de
+outros desenvolvedores, pode dar um impulso ao seu chaveiro contando com a
+descoberta e a recuperação automáticas de chaves. O GnuPG pode se apoiar em
+outras tecnologias de confiança delegada, a saber DNSSEC e TLS, para ajudá-lo,
+caso a perspectiva de começar a sua própria Teia de Confiança do zero seja
+intimidadora demais.
+
+Adicione o seguinte ao seu ``~/.gnupg/gpg.conf``::
+
+    auto-key-locate wkd,dane,local
+    auto-key-retrieve
+
+DNS-Based Authentication of Named Entities ("DANE") é um método para publicar
+chaves públicas no DNS e protegê-las usando zonas assinadas com DNSSEC. Web
+Key Directory ("WKD") é o método alternativo que usa consultas https para o
+mesmo propósito. Ao usar DANE ou WKD para procurar chaves públicas, o GnuPG
+validará certificados DNSSEC ou TLS, respectivamente, antes de adicionar as
+chaves recuperadas automaticamente ao seu chaveiro local.
+
+O kernel.org publica o WKD para todos os desenvolvedores que têm conta no
+kernel.org. Depois de fazer as mudanças acima no seu ``gpg.conf``, você pode
+recuperar automaticamente as chaves de Linus Torvalds e Greg Kroah-Hartman
+(se ainda não as tiver)::
+
+    $ gpg --locate-keys torvalds@kernel.org gregkh@kernel.org
+
+Se você tem conta no kernel.org, então deve `adicionar o UID do kernel.org à
+sua chave`_ para tornar o WKD mais útil para outros desenvolvedores do
+kernel.
+
+.. _`adicionar o UID do kernel.org à sua chave`: https://korg.docs.kernel.org/mail.html#adding-a-kernel-org-uid-to-your-pgp-key
+
+Web of Trust (WOT) versus Trust on First Use (TOFU)
+----------------------------------------------------
+
+O PGP incorpora um mecanismo de delegação de confiança conhecido como "Web of
+Trust". No fundo, é uma tentativa de substituir a necessidade de Autoridades
+Certificadoras centralizadas do mundo HTTPS/TLS. Em vez de vários fabricantes
+de software ditarem quem deve ser a sua entidade certificadora de confiança, o
+PGP deixa essa responsabilidade para cada usuário.
+
+Infelizmente, muito poucas pessoas entendem como a Web of Trust funciona.
+Embora ela ainda seja uma parte importante da especificação OpenPGP, versões
+recentes do GnuPG (2.2 e superiores) implementaram um mecanismo alternativo
+chamado "Trust on First Use" (TOFU). Você pode pensar no TOFU como "a
+abordagem de confiança ao estilo SSH". Com o SSH, na primeira vez que você se
+conecta a um sistema remoto, a impressão digital da chave dele é registrada e
+memorizada. Se a chave mudar no futuro, o cliente SSH avisará você e se
+recusará a conectar, forçando-o a decidir se confia ou não na chave alterada.
+De modo semelhante, na primeira vez que você importa a chave PGP de alguém,
+ela é considerada válida. Se em algum momento futuro o GnuPG encontrar outra
+chave com a mesma identidade, tanto a chave importada anteriormente quanto a
+nova serão marcadas para verificação, e você precisará descobrir manualmente
+qual delas manter.
+
+Recomendamos que você use o modelo de confiança combinado TOFU+PGP (que é o
+novo padrão no GnuPG v2). Para defini-lo, adicione (ou modifique) a
+configuração ``trust-model`` em ``~/.gnupg/gpg.conf``::
+
+    trust-model tofu+pgp
+
+.. _kernel_org_trust_repository:
+
+Usando o repositório de teia de confiança do kernel.org
+--------------------------------------------------------
+
+O kernel.org mantém um repositório Git com as chaves públicas dos
+desenvolvedores, como substituto para replicar redes de keyservers que se
+tornaram em grande parte inoperantes nos últimos anos. A documentação completa
+sobre como configurar esse repositório como a sua fonte de chaves públicas
+pode ser encontrada aqui:
+
+- `Kernel developer PGP Keyring`_
+
+Se você é desenvolvedor do kernel, considere enviar a sua chave para inclusão
+nesse chaveiro.
+
+.. _`Kernel developer PGP Keyring`: https://korg.docs.kernel.org/pgpkeys.html
+

-- 
2.53.0

