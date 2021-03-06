/**
 * Copyright (C) 2015 Orbeon, Inc.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the
 * GNU Lesser General Public License as published by the Free Software Foundation; either version
 * 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU Lesser General Public License for more details.
 *
 * The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
 */
package org.orbeon.oxf.fr

import org.orbeon.oxf.fb.FormBuilder._
import org.orbeon.oxf.fr.XMLNames._
import org.orbeon.saxon.om.{NodeInfo, SequenceIterator}
import org.orbeon.scaxon.XML._

trait FormRunnerEmail {

  // Given a form body and instance data:
  //
  // - find all controls with the given class name
  // - for each control, find the associated bind
  // - return all data holders in the instance data to which the bind would apply
  //
  // The use case is, for example, to find all data holders pointed to by controls with the class
  // `fr-email-recipient`.
  //
  //@XPathFunction
  def searchHoldersForClassTopLevelOnly(
    body      : NodeInfo,
    data      : NodeInfo,
    className : String
  ): SequenceIterator =
    searchHolderInDoc(
      controls    = body descendant * filter IsControl,
      inDoc       = body,
      contextItem = data.rootElement,
      className   = className
    )

  // Given a form head, form body and instance data:
  //
  // - find all section templates in use
  // - for each section
  //   - determine the associated data holder in instance data
  //   - find the inline binding associated with the section template
  //   - find all controls with the given class name in the section template
  //   - for each control, find the associated bind in the section template
  //   - return all data holders in the instance data to which the bind would apply
  //
  // The use case is, for example, to find all data holders pointed to by controls with the class
  // `fr-email-recipient` which appear within section templates.
  //
  //@XPathFunction
  def searchHoldersForClassUseSectionTemplates(
    head      : NodeInfo,
    body      : NodeInfo,
    data      : NodeInfo,
    className : String
  ): SequenceIterator =
    for {
      section       ← findSectionsWithTemplates(body)
      sectionName   ← getControlNameOpt(section).toList
      sectionHolder ← findDataHoldersInDocument(body, sectionName, data.rootElement)
      binding       ← bindingForSection(head, section).toList
      holder        ← searchHolderInDoc(
        controls    = binding.rootElement / XBLTemplateTest descendant * filter IsControl,
        inDoc       = binding,
        contextItem = sectionHolder,
        className   = className
      )
    } yield
      holder

  private def searchHolderInDoc(
    controls    : Seq[NodeInfo],
    inDoc       : NodeInfo,
    contextItem : NodeInfo,
    className   : String
  ): Seq[NodeInfo] =
    for {
      control       ← controls
      if control.attClasses(className)
      bindId        ← control /@ "bind" map (_.stringValue)
      bindName      ← controlNameFromIdOpt(bindId).toList
      holder        ← findDataHoldersInDocument(inDoc, bindName, contextItem)
    } yield
      holder

  private def bindingForSection(head: NodeInfo, section: NodeInfo) = {
    val mapping = sectionTemplateXBLBindingsByURIQualifiedName(head / XBLXBLTest)
    sectionTemplateBindingName(section) flatMap mapping.get
  }
}
