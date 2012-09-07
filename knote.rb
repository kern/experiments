require "parslet"
require "date"
require "builder"
require "thor"

module Knote
  Document = Struct.new(:subject, :date, :body)
  Section = Struct.new(:title, :body)
  Topic = Struct.new(:title, :body)
  Definition = Struct.new(:term, :description)
  Note = Struct.new(:text)

  class Parser < Parslet::Parser
    rule(:lf) { str("\n") }
    rule(:eof) { any.absent? }
    rule(:eol) { lf.repeat(1) | eof }
    rule(:digit) { match["0-9"] }
    rule(:text_char) { match["^\n"] }
    rule(:text) { text_char.repeat(1) }

    rule(:definition_separator) { str(" :: ") }
    rule(:definition_term) { (definition_separator.absent? >> text_char).repeat(1).as(:term) }
    rule(:definition_description) { text.as(:description) }
    rule(:definition) { (definition_term >> definition_separator >> definition_description).as(:definition) >> eol }
    rule(:note) { text.as(:note) >> eol }
    rule(:entry) { section_header.absent? >> topic_header.absent? >> (definition | note) }

    rule(:section_header) { str("= ") >> text.as(:title) >> eol }
    rule(:section_body) { (topic | entry).repeat.as(:body) }
    rule(:section) { (section_header >> section_body).as(:section) }

    rule(:topic_header) { ((str(":") >> eol).absent? >> text_char).repeat(1).as(:title) >> str(":") >> eol }
    rule(:topic_body) { entry.repeat.as(:body) }
    rule(:topic) { section_header.absent? >> (topic_header >> topic_body).as(:topic) }

    rule(:header) { date >> str(" - ") >> text.as(:subject) >> eol }
    rule(:date) { (digit.repeat(1, 2).as(:month) >> str("/") >> digit.repeat(1, 2).as(:day) >> str("/") >> digit.repeat(4).as(:year)).as(:date) }
    rule(:body) { (section | topic | entry).repeat.as(:body) }
    rule(:document) { header >> body }
    root(:document)
  end

  class Transform < Parslet::Transform
    rule(note: simple(:note)) { Note.new(note) }
    rule(definition: { term: simple(:term), description: simple(:description) }) { Definition.new(term, description) }
    rule(topic: { title: simple(:title), body: sequence(:body) }) { Topic.new(title, body) }
    rule(section: { title: simple(:title), body: sequence(:body) }) { Section.new(title, body) }
    rule(month: simple(:month), day: simple(:day), year: simple(:year)) { Date.new(year.to_i, month.to_i, day.to_i) }
    rule(date: subtree(:date), subject: simple(:subject), body: sequence(:body)) { Document.new(subject, date, body) }
  end

  class HTMLConvertor
    def convert(element, xml = Builder::XmlMarkup.new)
      case element
      when Document;
        xml.article do
          xml.h1 "Notes for #{element.subject} - #{element.date.strftime("%m/%d/%Y")}"
          convert_body(element, xml)
        end
      when Section
        xml.section class: "section" do
          xml.h2 element.title
          convert_body(element, xml)
        end
      when Topic
        xml.section class: "topic" do
          xml.h3 element.title
          convert_body(element, xml)
        end
      when Definition
        xml.div class: "definition" do
          xml.strong element.term, class: "term"
          xml.span element.description, class: "description"
        end
      when Note
        xml.div element.text, class: "note"
      end
    end

    private

    def convert_body(element, xml)
      element.body.each { |e| convert(e, xml) }
    end
  end

  class CLI < Thor
    desc "convert FILE", "Converts a file from Knotation to HTML"
    def convert(file)
      parser = Parser.new
      transform = Transform.new
      convertor = HTMLConvertor.new

      contents = File.read(file)
      ast = parser.parse(contents)
      document = transform.apply(ast)
      puts convertor.convert(document).to_s
    end
  end
end

Knote::CLI.start