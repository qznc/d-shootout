// The Computer Language Benchmarks Game
// http://shootout.alioth.debian.org/
// contributed by Michael Deardeuff (grignaak)
// but all the real work was done by Ben St. John
/*
 (Real) Differences between this and Ben's implementation (g++ #4):
    SPiece has a copy construtor
   Soln has a clone() property
   recordSolution uses the clone property
*/
import std.stdio;

//-- Enums, aliases, consts ----------
enum {X, Y, N_DIM};
enum {EVEN, ODD, N_PARITY};
enum {GOOD, BAD, ALWAYS_BAD};
enum {OPEN, CLOSED, N_FIXED};


alias uint BitVec;

const int N_COL = 5;
const int N_ROW = 10;
const int N_CELL = N_COL * N_ROW;
const int N_PIECE_TYPE = 10;
const int MAX_ISLAND_OFFSET = 1024;
const int N_ORIENT = 12;

//-- Globals -------------------------
IslandInfo g_islandInfo[MAX_ISLAND_OFFSET];
int g_nIslandInfo = 0;
OkPieces g_okPieces[N_ROW][N_COL];

const uint g_firstRegion[32] = [
   0x00, 0x01, 0x02, 0x03,   0x04, 0x01, 0x06, 0x07,
   0x08, 0x01, 0x02, 0x03,   0x0c, 0x01, 0x0e, 0x0f,

   0x10, 0x01, 0x02, 0x03,   0x04, 0x01, 0x06, 0x07,
   0x18, 0x01, 0x02, 0x03,   0x1c, 0x01, 0x1e, 0x1f
];

const uint g_flip[32] = [
   0x00, 0x10, 0x08, 0x18, 0x04, 0x14, 0x0c, 0x1c,
   0x02, 0x12, 0x0a, 0x1a, 0x06, 0x16, 0x0e, 0x1e,

   0x01, 0x11, 0x09, 0x19, 0x05, 0x15, 0x0d, 0x1d,
   0x03, 0x13, 0x0b, 0x1b, 0x07, 0x17, 0x0f, 0x1f,
];

const uint s_firstOne[32] = [
   0, 0, 1, 0,   2, 0, 1, 0,
   3, 0, 1, 0,   2, 0, 1, 0,

   4, 0, 1, 0,   2, 0, 1, 0,
   3, 0, 1, 0,   2, 0, 1, 0,
];

//-- Functions -----------------------
extern (C) void* memset(void*, int, int);

uint getMask(uint iPos) {return (1 << (iPos));}

int floor(int top, int bot) {
   int toZero = top / bot;
   // negative numbers should be rounded down, not towards zero
   if ((toZero * bot != top) && ((top < 0) != (bot <= 0)))
      toZero--;

   return toZero;
}

uint getFirstOne(BitVec v, uint startPos = 0) {
   if (v == cast(BitVec)0)
      return 0;

   uint iPos = startPos;
   BitVec mask = 0xff << startPos;
   while ((mask & v) == 0) {
      mask <<= 8;
      iPos += 8;
   }
   uint result = cast(uint)((mask & v) >> iPos);
   uint resultLow = result & 0x0f;
   if (resultLow != 0)
      iPos += s_firstOne[resultLow];
   else
      iPos += 4 + s_firstOne[result >> 4];

   return iPos;
}

uint countOnes(BitVec v) {
   uint n = 0;
   while (v) {
      n++;
      v = v & (v - 1);
   }

   return n;
}


uint flipTwoRows(uint bits) {
   uint flipped = g_flip[bits >> N_COL] << N_COL;
   return (flipped | g_flip[bits & Board.TOP_ROW]);
}

void markBad(IslandInfo info, uint mask, int eo, bool always) {
   info.hasBad[eo][OPEN] |= mask;
   info.hasBad[eo][CLOSED] |= mask;

   if (always)
      info.alwaysBad[eo] |= mask;
}

void initGlobals() {
   foreach (IslandInfo i; g_islandInfo)
      i = new IslandInfo();
   foreach (OkPieces[N_COL] os; g_okPieces)
      foreach (OkPieces o; os)
         o = new OkPieces();
}




//-- Classes -------------------------

class OkPieces {
   byte nPieces[N_PIECE_TYPE];
   uint pieceVec[N_PIECE_TYPE][N_ORIENT];
};


class IslandInfo {
   uint hasBad[N_FIXED][N_PARITY];
   uint isKnown[N_FIXED][N_PARITY];
   uint alwaysBad[N_PARITY];
};



class Soln {
   static const int NO_PIECE = -1;

   bool isEmpty() {return (m_nPiece == 0);}
   void popPiece() {m_nPiece--; m_synched = false;}
   void pushPiece(BitVec vec, int iPiece, int row) {
      SPiece p = m_pieces[m_nPiece++];
      p.vec = vec;
      p.iPiece = cast(short)iPiece;
      p.row = cast(short)row;
   }

   this() { m_synched = false; m_nPiece = false; init();}

   class SPiece {
      BitVec vec;
      short iPiece;
      short row;
      this() {}
      this(BitVec avec, uint apiece, uint arow) {
         vec = avec;
                iPiece = cast(short)apiece;
                row = cast(short)arow;
      }
      this(SPiece other) {
         vec = other.vec;
         iPiece = other.iPiece;
         row = other.row;
      }
   }

   SPiece m_pieces[N_PIECE_TYPE];
   uint m_nPiece;
   byte m_cells[N_ROW][N_COL];
   bool m_synched;

   void init() {
      foreach (SPiece s; m_pieces)
         s = new SPiece();
   }
   this(int fillVal) {
      init();
      m_nPiece = 0;
      fill(fillVal);
   }
   Soln clone() {
      Soln s = new Soln;
      for (uint i = 0; i < m_pieces.length; i++)
         s.m_pieces[i] = new SPiece(m_pieces[i]);

      s.m_nPiece = m_nPiece;
      s.m_cells[0..$] = m_cells[0..$];
      s.m_synched = m_synched;
      return s;
   }


   void fill(int val) {
      m_synched = false;
      memset(&m_cells, val, N_CELL);
   }

   override string toString() {
      string result;
      for (int y = 0; y < N_ROW; y++) {
         for (int x = 0; x < N_COL; x++) {
            int val = m_cells[y][x];
            result ~= ((val == NO_PIECE) ? '.' : cast(char)('0' + val));
            result ~= ' ';
         }
         result ~= '\n';

         // indent every second line
         if (y % 2 == 0)
            result ~= " ";
      }
      return result;
   }

   void setCells() {
      if (m_synched)
         return;

      for (uint iPiece = 0; iPiece < m_nPiece; iPiece++) {
         SPiece p = m_pieces[iPiece];
         BitVec vec = p.vec;
         byte pID = cast(byte)p.iPiece;
         int rowOffset = p.row;

         int nNewCells = 0;
         for (int y = rowOffset; y < N_ROW; y++) {
            for (int x = 0; x < N_COL; x++) {
               if (vec & 1) {
                  m_cells[y][x] = pID;
                  nNewCells++;
               }
               vec >>= 1;
            }
            if (nNewCells == Piece.N_ELEM)
               break;
         }
      }
      m_synched = true;
   }

   bool lessThan(Soln r) {
      if (m_pieces[0].iPiece != r.m_pieces[0].iPiece) {
         return m_pieces[0].iPiece < r.m_pieces[0].iPiece;
      }

      setCells();
      r.setCells();

      for (int y = 0; y < N_ROW; y++) {
         for (int x = 0; x < N_COL; x++) {
            int lval = m_cells[y][x];
            int rval = r.m_cells[y][x];

            if (lval != rval)
               return (lval < rval);
         }
      }

      return false; // solutions are equal
   }

   void spin(Soln spun) {
      setCells();

      // swap cells
      for (int y = 0; y < N_ROW; y++) {
         for (int x = 0; x < N_COL; x++) {
            byte flipped = m_cells[N_ROW - y - 1][N_COL - x - 1];
            spun.m_cells[y][x] = flipped;
         }
      }

      // swap first and last pieces (the rest aren't used)
      spun.m_pieces[0].iPiece = m_pieces[N_PIECE_TYPE - 1].iPiece;
      spun.m_synched = true;
   }
}


//------------
class Board {
   static const BitVec L_EDGE_MASK =
      (1L <<  0) | (1L <<  5) | (1L << 10) | (1L << 15) |
      (1L << 20) | (1L << 25) | (1L << 30);
   static const BitVec R_EDGE_MASK = L_EDGE_MASK << 4;
   static const BitVec TOP_ROW = (1 << N_COL) - 1;
   static const BitVec ROW_0_MASK =
      TOP_ROW | (TOP_ROW << 10) | (TOP_ROW << 20) | (TOP_ROW << 30);
   static const BitVec ROW_1_MASK = ROW_0_MASK << 5;
   static const BitVec BOARD_MASK = (1 << 30) - 1;

   static uint getIndex(uint x, uint y) { return y * N_COL + x; }

   Soln m_curSoln;
   Soln m_minSoln;
   Soln m_maxSoln;
   uint m_nSoln;

   this() {
      m_curSoln = new Soln(Soln.NO_PIECE), m_minSoln = new Soln(N_PIECE_TYPE),
           m_maxSoln = new Soln(Soln.NO_PIECE), m_nSoln = (0);
   }

   static bool badRegion(ref BitVec toFill, BitVec rNew)
   {
      // grow empty region, until it doesn't change any more
      BitVec region;
      do {
         region = rNew;

         // simple grow up/down
         rNew |= (region >> N_COL);
         rNew |= (region << N_COL);

         // grow right/left
         rNew |= (region & ~L_EDGE_MASK) >> 1;
         rNew |= (region & ~R_EDGE_MASK) << 1;

         // tricky growth
         BitVec evenRegion = region & (ROW_0_MASK & ~L_EDGE_MASK);
         rNew |= evenRegion >> (N_COL + 1);
         rNew |= evenRegion << (N_COL - 1);
         BitVec oddRegion = region & (ROW_1_MASK & ~R_EDGE_MASK);
         rNew |= oddRegion >> (N_COL - 1);
         rNew |= oddRegion << (N_COL + 1);

         // clamp against existing pieces
         rNew &= toFill;
      }
      while ((rNew != toFill) && (rNew != region));

      // subtract empty region from board
      toFill ^= rNew;

      uint nCells = countOnes(toFill);
      return (nCells % Piece.N_ELEM != 0);
   }

   static int hasBadIslands(BitVec boardVec, int row)
   {
      // skip over any filled rows
      while ((boardVec & TOP_ROW) == TOP_ROW) {
         boardVec >>= N_COL;
         row++;
      }

      uint iInfo = boardVec & ((1 << 2 * N_COL) - 1);
      IslandInfo info = g_islandInfo[iInfo];

      uint lastRow = (boardVec >> (2 * N_COL)) & TOP_ROW;
      uint mask = getMask(lastRow);
      uint isOdd = row & 1;
      uint* alwaysBad = &info.alwaysBad[isOdd];

      if (*alwaysBad & mask)
         return BAD;

      if (boardVec & (TOP_ROW << N_COL * 3))
         return calcBadIslands(boardVec, row);

      int isClosed = (row > 6); // because we track 3 rows
      uint* isKnownVector = &info.isKnown[isOdd][isClosed];
      uint* badIsleVector = &info.hasBad[isOdd][isClosed];

      if (*isKnownVector & mask)
         return ((*badIsleVector & mask) != 0);

      if (boardVec == 0)
         return GOOD;

      int hasBad = calcBadIslands(boardVec, row);

      *isKnownVector |= mask;
      if (hasBad)
         *badIsleVector |= mask;

      return hasBad;
   }
   static int calcBadIslands(BitVec boardVec, int row)
   {
      BitVec toFill = ~boardVec;
      if (row & 1) {
         row--;
         toFill <<= N_COL;
      }

      BitVec boardMask = BOARD_MASK; // all but the first two bits
      if (row > 4) {
         int boardMaskShift = (row - 4) * N_COL;
         boardMask >>= boardMaskShift;
      }
      toFill &= boardMask;

      // a little pre-work to speed things up
      BitVec bottom = (TOP_ROW << (5 * N_COL));
      bool filled = ((bottom & toFill) == bottom);
      while ((bottom & toFill) == bottom) {
         toFill ^= bottom;
         bottom >>= N_COL;
      }

      BitVec startRegion;
      if (filled || (row < 4))
         startRegion = bottom & toFill;
      else {
         startRegion = g_firstRegion[toFill & TOP_ROW];
         if (startRegion == 0)  {
            startRegion = (toFill >> N_COL) & TOP_ROW;
            startRegion = g_firstRegion[startRegion];
            startRegion <<= N_COL;
         }
         startRegion |= (startRegion << N_COL) & toFill;
      }

      while (toFill)    {
         if (badRegion(toFill, startRegion))
            return (toFill ? ALWAYS_BAD : BAD);
         int iPos = getFirstOne(toFill);
         startRegion = getMask(iPos);
      }

      return GOOD;
   }
   static void calcAlwaysBad() {
      for (uint iWord = 1; iWord < MAX_ISLAND_OFFSET; iWord++) {
         IslandInfo isleInfo = g_islandInfo[iWord];
         IslandInfo flipped = g_islandInfo[flipTwoRows(iWord)];

         for (uint i = 0, mask = 1; i < 32; i++, mask <<= 1) {
            uint boardVec = (i << (2 * N_COL)) | iWord;
            if (isleInfo.isKnown[0][OPEN] & mask)
               continue;

            int hasBad = calcBadIslands(boardVec, 0);
            if (hasBad != GOOD) {
               bool always = (hasBad==ALWAYS_BAD);
               markBad(isleInfo, mask, EVEN, always);

               uint flipMask = getMask(g_flip[i]);
               markBad(flipped, flipMask, ODD, always);
            }
         }
         flipped.isKnown[1][OPEN] = cast(uint)(-1);
         isleInfo.isKnown[0][OPEN] = cast(uint)(-1);
      }
   }

   static bool hasBadIslandsSingle(BitVec boardVec, int row)
   {
      BitVec toFill = ~boardVec;
      bool isOdd = cast(bool)(row & 1);
      if (isOdd) {
         row--;
         toFill <<= N_COL; // shift to even aligned
         toFill |= TOP_ROW;
      }

      BitVec startRegion = TOP_ROW;
      BitVec lastRow = TOP_ROW << (5 * N_COL);
      BitVec boardMask = BOARD_MASK; // all but the first two bits
      if (row >= 4)
         boardMask >>= ((row - 4) * N_COL);
      else if (isOdd || (row == 0))
         startRegion = lastRow;

      toFill &= boardMask;
      startRegion &= toFill;

      while (toFill)    {
         if (badRegion(toFill, startRegion))
            return true;
         int iPos = getFirstOne(toFill);
         startRegion = getMask(iPos);
      }

      return false;
   }

   void genAllSolutions(BitVec boardVec, uint placedPieces, uint row)
   {
      while ((boardVec & TOP_ROW) == TOP_ROW) {
         boardVec >>= N_COL;
         row++;
      }
      uint iNextFill = s_firstOne[~boardVec & TOP_ROW];
      OkPieces allowed = g_okPieces[row][iNextFill];

      int iPiece = getFirstOne(~placedPieces);
      int pieceMask = getMask(iPiece);
      for (; iPiece < N_PIECE_TYPE; iPiece++, pieceMask <<= 1)
      {
         // skip if we've already used this piece
         if (pieceMask & placedPieces)
            continue;

         placedPieces |= pieceMask;
         for (int iOrient = 0; iOrient < allowed.nPieces[iPiece]; iOrient++) {
            BitVec pieceVec = allowed.pieceVec[iPiece][iOrient];

            // check if piece conflicts with other pieces
            if (pieceVec & boardVec)
               continue;

            // add the piece to the board
            boardVec |= pieceVec;

            if (hasBadIslands(boardVec, row)) {
               boardVec ^= pieceVec;
               continue;
            }

            m_curSoln.pushPiece(pieceVec, iPiece, row);

            // recur or record solution
            if (placedPieces != Piece.ALL_PIECE_MASK)
               genAllSolutions(boardVec, placedPieces, row);
            else
               recordSolution(m_curSoln);

            // remove the piece before continuing with a new piece
            boardVec ^= pieceVec;
            m_curSoln.popPiece();
         }

         placedPieces ^= pieceMask;
      }
   }

   void recordSolution(Soln s) {
      m_nSoln += 2; // add solution and its rotation

      if (m_minSoln.isEmpty()) {
         m_minSoln = m_maxSoln = s.clone;
         return;
      }

      if (s.lessThan(m_minSoln))
         m_minSoln = s.clone;
      else if (m_maxSoln.lessThan(s))
         m_maxSoln = s.clone;

      Soln spun = new Soln();
      s.spin(spun);
      if (spun.lessThan(m_minSoln))
         m_minSoln = spun;
      else if (m_maxSoln.lessThan(spun))
         m_maxSoln = spun;
   }
}

//------------
class Piece {
   class Instance {
      ulong m_allowed;
      BitVec m_vec;
      int m_offset;
   };

   static const int N_ELEM = 5;
   static const int ALL_PIECE_MASK = (1 << N_PIECE_TYPE) - 1;
   static const uint SKIP_PIECE = 5; // it's magic!

   alias int TPts[N_ELEM][N_DIM];

   static const BitVec BaseVecs[N_PIECE_TYPE] = [
   0x10f, 0x0cb, 0x1087, 0x427, 0x465,
   0x0c7, 0x8423, 0x0a7, 0x187, 0x08f
   ];

   static Piece s_basePiece[N_PIECE_TYPE][N_ORIENT];

   Instance m_instance[N_PARITY];

   void init() {
      foreach (Instance i; m_instance)
         i = new Instance();
   }
   this() {init();}

   static this() {
   foreach (Piece[N_ORIENT] ps; s_basePiece)
      foreach (Piece p; ps)
         p = new Piece();
   }
   static void setCoordList(BitVec vec, TPts pts) {
      int iPt = 0;
      BitVec mask = 1;
      for (int y = 0; y < N_ROW; y++) {
         for (int x = 0; x < N_COL; x++) {
            if (mask & vec) {
               pts[iPt][X] = x;
               pts[iPt][Y] = y;

               iPt++;
            }
            mask <<= 1;
         }
      }
   }

   static BitVec toBitVector(TPts pts) {
      int y, x;
      BitVec result = 0;
      for (int iPt = 0; iPt < N_ELEM; iPt++) {
         x = pts[iPt][X];
         y = pts[iPt][Y];

         int pos = Board.getIndex(x, y);
         result |= (1 << pos);
      }

      return result;
   }

   static void shiftUpLines(TPts pts, int shift) {
      // vertical shifts have a twist
      for (int iPt = 0; iPt < N_ELEM; iPt++) {
         int* rx = &pts[iPt][X];
         int* ry = &pts[iPt][Y];

         if (*ry & shift & 0x1)
            (*rx)++;
         *ry -= shift;
      }
   }

   static int shiftToX0(TPts pts, Instance instance, int offsetRow)
   {
      // .. determine shift
      int x, y, iPt;
      int xMin = pts[0][X];
      int xMax = xMin;
      for (iPt = 1; iPt < N_ELEM; iPt++) {
         x = pts[iPt][X];
         y = pts[iPt][Y];

         if (x < xMin)
            xMin = x;
         else if (x > xMax)
            xMax = x;
      }

      // I'm dying for a 'foreach' here
      int offset = N_ELEM;
      for (iPt = 0; iPt < N_ELEM; iPt++) {
         int* rx = &pts[iPt][X];
         int* ry = &pts[iPt][Y];

         *rx -= xMin;

         // check offset -- leftmost cell on top line
         if ((*ry == offsetRow) && (*rx < offset))
            offset = *rx;
      }

      instance.m_offset = offset;
      instance.m_vec = toBitVector(pts);
      return xMax - xMin;
   }

   void setOkPos(uint isOdd, int w, int h) {
      Instance p = m_instance[isOdd];
      p.m_allowed = 0;
      ulong posMask = 1UL << (isOdd * N_COL);

      for (int y = isOdd; y < N_ROW - h; y+=2, posMask <<= N_COL) {
         if (p.m_offset)
            posMask <<= p.m_offset;

         for (int xPos = 0; xPos < N_COL - p.m_offset; xPos++, posMask <<= 1) {
            // check if the new position is on the board
            if (xPos >= N_COL - w)
               continue;

            // move it to the desired location
            BitVec pieceVec = p.m_vec << xPos;

            if (Board.hasBadIslandsSingle(pieceVec, y))
               continue;

            // position is allowed
            p.m_allowed |= posMask;
         }
      }
   }

   static void genOrientation(BitVec vec, uint iOrient, Piece target)
   {
      // get (x,y) coordinates
      TPts pts;
      setCoordList(vec, pts);

      int y, x, iPt;
      int rot = iOrient % 6;
      int flip = iOrient >= 6;
      if (flip) {
         for (iPt = 0; iPt < N_ELEM; iPt++)
            pts[iPt][Y] = -pts[iPt][Y];
      }

      // rotate as necessary
      while (rot--) {
         for (iPt = 0; iPt < N_ELEM; iPt++) {
            x = pts[iPt][X];
            y = pts[iPt][Y];

            // I just worked this out by hand. Took a while.
            int xNew = floor((2 * x - 3 * y + 1), 4);
            int yNew = floor((2 * x + y + 1), 2);
            pts[iPt][X] = xNew;
            pts[iPt][Y] = yNew;
         }
      }

      // determine vertical shift
      int yMin = pts[0][Y];
      int yMax = yMin;
      for (iPt = 1; iPt < N_ELEM; iPt++) {
         y = pts[iPt][Y];

         if (y < yMin)
            yMin = y;
         else if (y > yMax)
            yMax = y;
      }
      int h = yMax - yMin;
      Instance even = target.m_instance[EVEN];
      Instance odd = target.m_instance[ODD];

      shiftUpLines(pts, yMin);
      int w = shiftToX0(pts, even, 0);
      target.setOkPos(EVEN, w, h);
      even.m_vec >>= even.m_offset;

      // shift down one line
      shiftUpLines(pts, -1);
      w = shiftToX0(pts, odd, 1);
      // shift the bitmask back one line
      odd.m_vec >>= N_COL;
      target.setOkPos(ODD, w, h);
      odd.m_vec >>= odd.m_offset;
   }

   static void genAllOrientations() {
      for (int iPiece = 0; iPiece < N_PIECE_TYPE; iPiece++) {
         BitVec refPiece = BaseVecs[iPiece];
         for (int iOrient = 0; iOrient < N_ORIENT; iOrient++) {
            Piece p = s_basePiece[iPiece][iOrient];
            genOrientation(refPiece, iOrient, p);
            if ((iPiece == SKIP_PIECE) && ((iOrient / 3) & 1))
               p.m_instance[0].m_allowed = p.m_instance[1].m_allowed = 0;
         }
      }
      for (int iPiece = 0; iPiece < N_PIECE_TYPE; iPiece++) {
         for (int iOrient = 0; iOrient < N_ORIENT; iOrient++) {
            ulong mask = 1;
            for (int iRow = 0; iRow < N_ROW; iRow++) {
               Instance p = getPiece(iPiece, iOrient, (iRow & 1));
               for (int iCol = 0; iCol < N_COL; iCol++) {
                  OkPieces allowed = g_okPieces[iRow][iCol];
                  if (p.m_allowed & mask) {
                     byte* nPiece = &allowed.nPieces[iPiece];
                     allowed.pieceVec[iPiece][*nPiece] = p.m_vec << iCol;
                     (*nPiece)++;
                  }

                  mask <<= 1;
               }
            }
         }
      }
   }


   static Instance getPiece(uint iPiece, uint iOrient, uint iParity) {
      return s_basePiece[iPiece][iOrient].m_instance[iParity];
   }
}



//-- Main ----------------------------
int main(string[] args) {
   if (args.length > 2)
      return 1; // spec says this is an error

   initGlobals();
   Board b = new Board();
   Piece.genAllOrientations();
   Board.calcAlwaysBad();
   b.genAllSolutions(0, 0, 0);

   writeln(b.m_nSoln, " solutions found\n");
   writeln(b.m_minSoln);
   writeln(b.m_maxSoln);

   return 0;
}
