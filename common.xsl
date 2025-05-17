<?xml version="1.0" encoding="UTF-8"?>
<transform
    version="1.0"
    xmlns="http://www.w3.org/1999/XSL/Transform"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:br="http://jabarsz.cz/Breezipe"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl">

  <!-- The root of the recipe document, for easy access. -->
  <variable name="root" select="/" />

  <!-- Don't copy "structural" elements by default, individual
       templates will choose to where/how to display them.  -->
  <template match="br:name|br:note" />

  <!-- General getters for breezipe elements  -->

  <template name="get-name">
    <choose>
      <when test="@name"><value-of select="@name" /></when>
      <when test="br:name"><copy-of select="br:name[last()]/node()" /></when>
      <when test="self::br:result"><apply-templates /></when>
      <otherwise>
        <if test="self::br:recipes">
          <for-each select="br:recipe[last()]">
            <call-template name="get-name" />
          </for-each>
        </if>
      </otherwise>
    </choose>
  </template>

  <template name="get-name-or-id">
    <variable name="name-tmp">
      <call-template name="get-name" />
    </variable>
    <variable name="name" select="exsl:node-set($name-tmp)" />
    <choose>
      <when test="$name != ''"><value-of select="$name" /></when>
      <when test="@id"><value-of select="@id" /></when> <!-- Fallback -->
      <otherwise>
        <message terminate="yes">
          Element <value-of select="name(.)" /> doesn't have a name or id.
        </message>
      </otherwise>
    </choose>
  </template>

  <!-- The following template makes it easier to call get-name-or-id
       on a 'select'-ed nodes. <call-template> doesn't have a 'select'
       attr., but <apply-templates> does. <apply-templates> doesn't
       have a 'name' attr. though, so we use 'mode'. This saves a
       <foreach> at the callsite. -->
  <template match="*" mode="get-name-or-id">
    <call-template name="get-name-or-id" />
  </template>

  <template name="get-quantity">
    <value-of select="@quantity" />
    <if test="@unit">
      <text> </text>
      <value-of select="@unit" />
    </if>
  </template>

  <!-- XHTML generators for cross-referenced elements -->

  <template name="link">
    <param name="extra-classes" select="''" />
    <param name="extra-attrs-from" />
    <param name="text">
      <apply-templates />
    </param>
    <xhtml:a>
      <attribute name="href">
        <text>#</text><call-template name="get-id" />
      </attribute>
      <attribute name="class">
        <text>internal </text>
        <value-of select="$extra-classes" />
      </attribute>
      <copy-of select="exsl:node-set($extra-attrs-from)/node()/@*" />
      <copy-of select="$text" />
    </xhtml:a>
  </template>

  <template name="target">
    <attribute name="id"><call-template name="get-id" /></attribute>
  </template>

  <template name="crossrefd">
    <text>crossrefd </text>
    <call-template name="get-id" />
  </template>

  <template name="class-attr">
    <param name="extra-classes" select="''" />
    <attribute name="class">
      <call-template name="crossrefd" />
      <text> </text>
      <value-of select="$extra-classes" />
    </attribute>
    <attribute name="data-crossref">
      <call-template name="get-id" />
    </attribute>
  </template>

  <!-- Other generators -->

  <template name="qty-note-parens">
    <if test="@quantity or @note or br:note">
      <text> (</text>
      <call-template name="get-quantity" />
      <if test="@quantity and (@note or br:note)">
        <text>, </text>
      </if>
      <if test="@note"><value-of select="@note" /></if>
      <if test="br:note"><copy-of select="br:note/node()" /></if>
      <text>)</text>
    </if>
  </template>

  <!-- Declarations related to IDs -->

  <!--
      Instead of using the XPath 'id' function, we use 'key', because
      some processors are strict about using the 'xml:id' attribute
      instead of the shorter 'id'. It seems preferable to avoid the
      more verbose version in user-facing instance documents.
  -->
  <key name="id" match="//node()" use="@id" />

  <!--
      'get-id' gets the ID of a node if there is one or if one was
      saved for a copied node, and otherwise generated a descriptive
      ID with the help of the 'descriptive-id' mode template.
  -->
  <template name="get-id">
    <!-- For nodes copied by this project's templates, we save the
         original 'generate-id()' into the attr. 'generated-id'. -->
    <variable name="gid-tree">
      <choose>
        <when test="@generated-id">
          <value-of select="@generated-id" />
        </when>
        <otherwise><value-of select="generate-id()" /></otherwise>
      </choose>
    </variable>
    <variable name="gid" select="exsl:node-set($gid-tree)" />
    <choose>
      <when test="@id"><value-of select="@id" /></when>
      <otherwise>
        <variable name="descriptive-id">
          <apply-templates select="." mode="descriptive-id">
            <with-param name="id" select="$gid" />
          </apply-templates>
        </variable>
        <choose>
          <when test="exsl:node-set($descriptive-id)/text()">
            <value-of select="exsl:node-set($descriptive-id)" />
          </when>
          <otherwise>
            <value-of select="$gid" />
          </otherwise>
        </choose>
      </otherwise>
    </choose>
  </template>

  <!--
      Make an ID more descriptive by appending some descriptive text
      about the current node. This template easily overridden if
      needed. Note that it might produce invalid IDs in some cases, so
      you might want to turn it off by overriding it with an empty
      template.
  -->
  <template match="*" mode="descriptive-id">
    <param name="id" select="@id" />

    <variable name="desc">
      <choose>
        <when test="@name or br:name">
          <call-template name="get-name" />
        </when>
        <when test="text()">
          <value-of select="text()" />
        </when>
        <otherwise />
      </choose>
    </variable>

    <if test="exsl:node-set($desc)/text()">
      <!-- Make the text an ID by removing some disallowed chars  -->
      <!-- FIXME this is not exhaustive & may produce invalid ids -->
      <variable name="xmlized"
                select="translate(exsl:node-set($desc),
                        ' :@$%/+,;&amp;&#10;',
                        '___________')" />
      <value-of select="concat(concat($id, '-'), $xmlized)" />
    </if>
  </template>

</transform>
