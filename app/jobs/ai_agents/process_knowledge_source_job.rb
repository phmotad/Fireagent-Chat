# frozen_string_literal: true

class AiAgents::ProcessKnowledgeSourceJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 1.minute, attempts: 3

  def perform(knowledge_source_id)
    @knowledge_source = AiAgentKnowledgeSource.find(knowledge_source_id)

    begin
      process_knowledge_source
    rescue StandardError => e
      handle_error(e)
    end
  end

  private

  def process_knowledge_source
    @knowledge_source.update!(status: 'processing')

    # 1. Read file content
    content = read_file_content

    if content.blank?
      raise "Failed to read file content from #{@knowledge_source.file_path}"
    end

    # 2. Send to fireagent-brain /ingest endpoint
    response = send_to_ingest_service(content)

    # 3. Update status
    @knowledge_source.update!(status: 'ready')

    Rails.logger.info("Knowledge source #{@knowledge_source.id} processed successfully. " \
                      "Chunks: #{response[:chunks_processed]}/#{response[:total_chunks]}")
  end

  def read_file_content
    file_path = @knowledge_source.file_path
    content = nil

    # Check if it's a URL
    if file_path.start_with?('http://', 'https://')
      content = download_from_url(file_path)
    # Check if it's an ActiveStorage attachment
    elsif @knowledge_source.respond_to?(:document) && @knowledge_source.document.attached?
      content = @knowledge_source.document.download
    # Check if it's a local file path
    elsif File.exist?(file_path)
      content = File.read(file_path)
    else
      raise "File not found: #{file_path}"
    end

    # Extract text from PDF if needed
    if file_path.downcase.end_with?('.pdf')
      extract_text_from_pdf(content)
    else
      content
    end
  end

  def extract_text_from_pdf(pdf_content)
    require 'pdf-reader'

    begin
      reader = PDF::Reader.new(StringIO.new(pdf_content))
      text_parts = []

      reader.pages.each_with_index do |page, index|
        begin
          text = page.text
          text_parts << text if text.present?
        rescue StandardError => e
          Rails.logger.warn("Error extracting text from page #{index}: #{e.message}")
        end
      end

      extracted_text = text_parts.join("\n\n")

      if extracted_text.blank?
        raise "No text could be extracted from PDF"
      end

      Rails.logger.info("Extracted #{extracted_text.length} characters from PDF with #{reader.page_count} pages")
      extracted_text
    rescue StandardError => e
      raise "Failed to extract text from PDF: #{e.message}"
    end
  end

  def download_from_url(url)
    require 'open-uri'
    URI.open(url, &:read)
  rescue StandardError => e
    raise "Failed to download from URL: #{e.message}"
  end

  def send_to_ingest_service(content)
    require 'net/http'
    require 'json'

    uri = URI("#{fireagent_brain_url}/ingest")

    request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    request.body = {
      agent_id: @knowledge_source.ai_agent_id,
      file_path: @knowledge_source.file_path,
      content: content,
      metadata: @knowledge_source.metadata || {}
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.read_timeout = 300 # 5 minutes for large files
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body, symbolize_names: true)
    else
      raise "Ingest service returned error: #{response.code} - #{response.body}"
    end
  end

  def fireagent_brain_url
    ENV.fetch('FIREAGENT_BRAIN_URL', 'http://fireagent-brain:8000')
  end

  def handle_error(error)
    @knowledge_source.update!(
      status: 'failed',
      metadata: @knowledge_source.metadata.merge(
        error: error.message,
        failed_at: Time.current
      )
    )

    Rails.logger.error("Failed to process knowledge source #{@knowledge_source.id}: #{error.message}")
    Rails.logger.error(error.backtrace.join("\n"))
  end
end
