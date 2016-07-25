class Levenshtein
  extend Rusby::Core

  def rust(f)
  end

  def rust_variable(f)
  end

  rusby!
  def distance(s, t)
    m = s.length
    n = t.length

    return m if n == 0
    return n if m == 0
    d = Array.new(m + 1) { Array.new(n + 1) }

    (0..m).each { |i| d[i][0] = i }
    (0..n).each { |j| d[0][j] = j }
    (1..n).each do |j|
      (1..m).each do |i|
        d[i][j] = if s[i - 1] == t[j - 1]     # adjust index into string
                    d[i - 1][j - 1]           # no operation required
                  else
                    deletion = d[i - 1][j] + 1
                    insertion = d[i][j - 1] + 1
                    substitution = d[i - 1][j - 1] + 1
                    op = deletion < insertion ? deletion : insertion
                    op < substitution ? op : substitution
                  end
      end
    end
    return d[m][n]
  end
end
