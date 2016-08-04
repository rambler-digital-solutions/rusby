class Quicksort
  extend Rusby::Core

  rusby!
  def quicksort(a, lo, hi)
    return a unless lo < hi
    pivot = partition(a, lo, hi)
    quicksort(a, lo, pivot)
    quicksort(a, pivot + 1, hi)
    a
  end

  private

  def partition(a, lo, hi)
    pivot = a[lo]
    i = lo - 1
    j = hi + 1
    loop do
      begin
        i += 1
      end while a[i] < pivot

      begin
        j -= 1
      end while a[j] > pivot

      return j if i >= j
      a[i], a[j] = [a[j], a[i]]
    end
  end
end
