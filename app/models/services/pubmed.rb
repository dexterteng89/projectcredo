class Pubmed
  class Http
    def default_parameters
      {
        db: 'pubmed',
        retmode: 'json',
        retmax: 20
      }
    end

    def base_url
      'https://eutils.ncbi.nlm.nih.gov'
    end

    def esearch_url params = {}
      generate_uri(base_url + "/entrez/eutils/esearch.fcgi", default_parameters.merge(params))
    end

    def esummary_url params = {}
      generate_uri(base_url + "/entrez/eutils/esummary.fcgi", default_parameters.merge(params))
    end

    def efetch_url params = {}
      generate_uri(base_url + "/entrez/eutils/efetch.fcgi", default_parameters.merge(params))
    end

    def esearch term:
      parse_response(esearch_url term: term)
    end

    def esummary id:
      parse_response(esummary_url id: id)
    end

    def efetch id: , type:
      type = type.to_s
      parse_response(efetch_url(id: id, retmode: type), type: type)
    end

    private
      def generate_uri(url, parameters)
        URI.parse(url + '?' + URI.encode_www_form(parameters))
      end

      def parse_response uri, type: 'json'
        response = Net::HTTP.get(uri)
        if type.to_s == 'xml'
          return Hash.from_xml(CGI.unescapeHTML response)
        else
          return JSON.parse(response)
        end
      end
  end
end

class Pubmed
  attr_accessor :http

  def initialize
    self.http = Pubmed::Http.new
  end

  def get_search_result_ids query
    query = query.gsub(/\s/, '+')
    http.esearch(term: query).dig 'esearchresult', 'idlist'
  end

  def get_uid_from_doi doi
    http.esearch(term: doi).dig 'esearchresult', 'idlist', 0
  end

  def search(query)
    http.esummary id: get_search_result_ids(query).join(",")
  end

  def get_summary(uid)
    http.esummary(id: uid)
  end

  def get_full_details(uid)
    http.efetch(id: uid, type: 'xml')
  end

  def get_abstract(uid)
    full_details = get_full_details(uid)

    full_details.dig *%w{
      PubmedArticleSet
      PubmedArticle
      MedlineCitation
      Article
      Abstract
      AbstractText
    }
  end
end
