class SearchesController < ApplicationController
  # Janky
  def search
    @query = params[:q]

    if params[:q].length > 0
      q = params[:q].downcase
      @language = Book.all.select{ |book| book if are_close?(q, book.source_language.downcase) || are_close?(q, book.target_language.downcase) || are_close?(q, book.title.downcase)}.sort_by{|book| book.created_at}
        .reverse
        .map do |book|
          BookSerializer.new(book)
        end

      @user = User.all.select{ |user| user if are_close?(q, user.username.downcase) }.sort_by{|user| user.created_at}
        .reverse
        .map do |user|
          UserSerializer.new(user)
        end

      # @phrase = PhrasePair.where("source_phrase || target_phrase ilike ?", q).sort_by{|phrasePair| phrasePair.created_at}
      #   .reverse
      #   .map do |phrase|
      #     PhraseSerializer.new(phrase)
      #   end

      render 'search/index'

    else
      redirect_to '/'
    end

  end

  private
    #Damerau–Levenshtein distance algorithm (https://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance)
    def are_close?(q, target)

      # Initialization for the algorithm
      query_length = q.length
      target_length = target.length

      char_dictionary = {}

      distance_2d_array = Array.new(query_length+1){Array.new(target_length+1){0}}

      for i in 0..query_length do
        distance_2d_array[i][0] = i
      end

      for j in 0..target_length do
        distance_2d_array[0][j] = j
      end

      # Populate a dictionary with alphapets of the two strings
      q.each_char{ |char| char_dictionary[char] = 0 }
      target.each_char{ |char| char_dictionary[char] = 0 }

      #Determine substring distances
      for i in 1..query_length do
        db = 0
        for j in 1..target_length do
          i1 = char_dictionary[target[j-1]]
          j1 = db
          cost = 0

          if q[i-1] == target[j-1]
            db = j
          else
            cost = 1
          end

          distance_2d_array[i][j] = [
            distance_2d_array[i][j-1] + 1, #insertion
            distance_2d_array[i-1][j] + 1, #deletion
            distance_2d_array[i-1][j-1] + cost #substitution
          ].min

          if i1 > 0 && j1 > 0
            distance_2d_array[i][j] = [
              distance_2d_array[i][j],
              distance_2d_array[i1-1][j1-1] + (i-i1-1) + (j-j1-1) + 1
            ].min #transposition
          end
        end

        char_dictionary[q[i-1]] = i
      end

      # You can change 'desired_distance' value so that catching more results will happen
      desired_distance = 4

      return distance_2d_array[query_length][target_length] <= desired_distance
    end
end
