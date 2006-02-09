<!--
    Copyright (C) 2005 Orbeon, Inc.

    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.

    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
-->
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xi="http://www.w3.org/2003/XInclude"
    xmlns:saxon="http://saxon.sf.net/"
    xmlns:local="http://orbeon.org/oxf/xml/local">

    <xsl:import href="../util/blog-functions.xsl"/>

    <xsl:output method="html" omit-xml-declaration="yes" name="html-output"/>

    <xsl:variable name="instance" select="doc('input:instance')/*" as="element()"/>
    <xsl:variable name="blog" select="doc('input:blog')/*" as="element()"/>
    <xsl:variable name="post" select="doc('input:post')/*" as="element()"/>
    <xsl:variable name="posts" select="doc('input:posts')/*" as="element()"/>
    <xsl:variable name="categories" select="doc('input:categories')/*/*" as="element()*"/>
    <xsl:variable name="only-one-post" select="exists($post/post-id)" as="xs:boolean"/>

    <xsl:template match="/">

        <recent-posts>

            <submission>
                <xsl:copy-of select="$instance"/>
            </submission>

            <user>
                <username><xsl:value-of select="$instance/username"/></username>
            </user>

            <xsl:copy-of select="$blog"/>

            <categories>
                <category>
                    <name>All</name>
                    <id/>
                    <link>
                        <xsl:value-of select="local:blog-path($instance/username, $blog/blog-id, ())"/>
                    </link>
                </category>
                <xsl:for-each select="$categories">
                    <xsl:copy>
                        <xsl:copy-of select="*"/>
                        <link>
                            <xsl:value-of select="local:blog-path($instance/username, $blog/blog-id, id)"/>
                        </link>
                    </xsl:copy>
                </xsl:for-each>
            </categories>

            <feeds>
                <feed>
                    <name>All</name>
                    <link><xsl:value-of select="local:blog-feed-path($instance/username, $blog/blog-id, 'rss20', ())"/></link>
                </feed>
                <xsl:for-each select="$categories">
                    <feed>
                        <name><xsl:value-of select="name"/></name>
                        <link><xsl:value-of select="local:blog-feed-path($instance/username, $blog/blog-id, 'rss20', id)"/></link>
                    </feed>
                </xsl:for-each>
            </feeds>

            <posts>
                <xsl:for-each-group select="$posts/post[published = 'true' and (not($only-one-post) or post-id = $post/post-id)]" group-by="xs:date(xs:dateTime(date-created))">
                    <xsl:sort select="xs:dateTime(date-created)" order="descending"/>
                    <day>
                        <date><xsl:value-of select="xs:date(xs:dateTime(date-created))"/></date>
                        <formatted-date><xsl:value-of select="local:format-dateTime-default(date-created, true())"/></formatted-date>

                        <xsl:for-each select="current-group()">
                            <xsl:sort select="xs:dateTime(date-created)" order="descending"/>

                            <xsl:copy>
                                <xsl:copy-of select="* except (content, categories)"/>
                                <content>
                                    <xsl:variable name="content" select="saxon:serialize(content, 'html-output')" as="xs:string"/>
                                    <xsl:variable name="content-end" select="substring-after($content, '&gt;')" as="xs:string"/>
                                    <xsl:value-of select="substring($content-end, 1, string-length($content-end) - 10)"/>
                                </content>
                                <categories>
                                    <xsl:for-each select="categories/category-id">
                                        <xsl:for-each select="$categories[id = current()]">
                                            <xsl:copy>
                                                <xsl:copy-of select="*"/>
                                                <link>
                                                    <xsl:value-of select="local:blog-path($instance/username, $blog/blog-id, id)"/>
                                                </link>
                                            </xsl:copy>
                                        </xsl:for-each>
                                    </xsl:for-each>
                                </categories>
                                <comments>
                                    <xsl:if test="$only-one-post">
                                        <!-- Tells whether comments should be displayed -->
                                        <xsl:attribute name="show" select="'true'"/>
                                        <!-- All the comments -->
                                        <xsl:copy-of select="doc('input:comments')/*/comment"/>
                                    </xsl:if>
                                </comments>
                                <links>
                                    <fragment-name><xsl:value-of select="concat('post-', post-id)"/></fragment-name>
                                    <post><xsl:value-of select="local:post-path($instance/username, $blog/blog-id, post-id)"/></post>
                                    <comments><xsl:value-of select="local:comments-path($instance/username, $blog/blog-id, post-id)"/></comments>
                                    <category></category>
                                </links>
                                <formatted-date-created><xsl:value-of select="local:format-dateTime-default(date-created, true())"/></formatted-date-created>
                                <formatted-dateTime-created><xsl:value-of select="local:format-dateTime-default(date-created, false())"/></formatted-dateTime-created>
                            </xsl:copy>

                        </xsl:for-each>
                    </day>
                </xsl:for-each-group>
            </posts>

        </recent-posts>
    </xsl:template>
</xsl:stylesheet>